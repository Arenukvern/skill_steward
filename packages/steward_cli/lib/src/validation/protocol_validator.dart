const _allowedModes = {
  'tool-execution',
  'steward-presence',
  'delegation',
  'sub-steward-lens',
};

const _allowedStatuses = {
  'stewardship_protocol',
  'steward_presence',
  'proven_repo_steward',
  'sub_steward',
};

const _modeEventFields = {
  'schema',
  'id',
  'created_at',
  'repo',
  'mode',
  'status',
  'intent',
  'delegated_surface',
  'evidence_bar',
  'boundary_signals',
  'self_model_pointer',
  'non_claims',
};

const _selfModelFields = {
  'schema',
  'steward_id',
  'repo',
  'status',
  'identity_role',
  'boundary_awareness',
  'open_questions',
  'values_in_action',
  'reflective_state',
  'trigger_event_id',
  'consent_basis',
  'visibility',
  'retention',
  'redaction_policy',
  'non_claims',
  'validation',
};

const _forbiddenPrivateMaterial = [
  'BEGIN PRIVATE KEY',
  'OPENAI_API_KEY',
  'ANTHROPIC_API_KEY',
  'SECRET_ACCESS_KEY',
  'password:',
  'password=',
  'token:',
  'raw chat log',
  'raw_chat_log',
  'raw memory',
  'raw_memory',
  'chain of thought',
];

class ProtocolValidator {
  const ProtocolValidator();

  List<String> validateModeEvent(final Map<String, dynamic> event) {
    final diagnostics = <String>[];

    _rejectUnknownFields(event, _modeEventFields, 'mode event', diagnostics);
    _requireExactString(event, 'schema', 'steward/mode-event/v1', diagnostics);
    for (final field in [
      'id',
      'created_at',
      'repo',
      'intent',
      'evidence_bar',
    ]) {
      _requireNonEmptyString(event, field, diagnostics);
    }
    _requireEnumString(event, 'mode', _allowedModes, diagnostics);
    _requireEnumString(event, 'status', _allowedStatuses, diagnostics);
    _requireStringList(event, 'non_claims', diagnostics, minItems: 1);

    if (event.containsKey('boundary_signals')) {
      _requireStringList(event, 'boundary_signals', diagnostics);
    }
    if (event.containsKey('delegated_surface')) {
      _requireStringIfPresent(event, 'delegated_surface', diagnostics);
    }
    if (event.containsKey('self_model_pointer')) {
      _requireStringIfPresent(event, 'self_model_pointer', diagnostics);
    }
    _validateModeStatusInvariants(event, diagnostics);

    return diagnostics;
  }

  List<String> validateSelfModel(final Map<String, dynamic> selfModel) {
    final diagnostics = <String>[];

    _rejectUnknownFields(
      selfModel,
      _selfModelFields,
      'self-model',
      diagnostics,
    );
    _requireExactString(
      selfModel,
      'schema',
      'steward/self-model/v1',
      diagnostics,
    );
    for (final field in [
      'steward_id',
      'repo',
      'identity_role',
      'reflective_state',
      'trigger_event_id',
      'consent_basis',
      'visibility',
      'retention',
      'redaction_policy',
    ]) {
      _requireNonEmptyString(selfModel, field, diagnostics);
    }
    _requireEnumString(selfModel, 'status', _allowedStatuses, diagnostics);
    _requireStringList(
      selfModel,
      'boundary_awareness',
      diagnostics,
      minItems: 1,
    );
    _requireStringList(selfModel, 'open_questions', diagnostics);
    _requireStringList(selfModel, 'values_in_action', diagnostics, minItems: 1);
    _requireStringList(selfModel, 'non_claims', diagnostics, minItems: 1);

    if (selfModel['status'] == 'proven_repo_steward') {
      final validation = selfModel['validation'];
      if (validation is! Map) {
        diagnostics.add(
          'validation is required before claiming proven_repo_steward.',
        );
      } else {
        _validateProvenStewardValidation(
          Map<String, dynamic>.from(validation),
          diagnostics,
        );
      }
    }

    return diagnostics;
  }

  List<String> validateNoRawPrivateMaterial(final String text) {
    final diagnostics = <String>[];
    final lowerText = text.toLowerCase();
    for (final marker in _forbiddenPrivateMaterial) {
      if (lowerText.contains(marker.toLowerCase())) {
        diagnostics.add('contains forbidden private material marker: $marker');
      }
    }
    return diagnostics;
  }
}

void _rejectUnknownFields(
  final Map<String, dynamic> object,
  final Set<String> allowed,
  final String label,
  final List<String> diagnostics,
) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      diagnostics.add('$key is not an allowed $label field.');
    }
  }
}

void _validateModeStatusInvariants(
  final Map<String, dynamic> event,
  final List<String> diagnostics,
) {
  final mode = event['mode'];
  final status = event['status'];
  if (mode == 'tool-execution' && status != 'stewardship_protocol') {
    diagnostics.add(
      'mode/status mismatch: tool-execution may only record stewardship_protocol status.',
    );
  }
  if (mode == 'delegation' &&
      (event['delegated_surface'] is! String ||
          (event['delegated_surface'] as String).trim().isEmpty)) {
    diagnostics.add('delegation mode requires delegated_surface.');
  }
  if (mode == 'sub-steward-lens' && status == 'sub_steward') {
    diagnostics.add(
      'sub-steward-lens mode is temporary; persistent sub_steward status requires self-model validation.',
    );
  }
}

void _validateProvenStewardValidation(
  final Map<String, dynamic> validation,
  final List<String> diagnostics,
) {
  const allowedValidationFields = {
    'tasks',
    'comparison',
    'outcome',
    'falsifier',
    'reviewer',
    'updated_at',
    'non_claims',
  };
  _rejectUnknownFields(
    validation,
    allowedValidationFields,
    'validation',
    diagnostics,
  );

  _requireObjectList(
    validation,
    'tasks',
    diagnostics,
    path: 'validation.tasks',
    minItems: 2,
  );
  final comparison = validation['comparison'];
  if (comparison is! Map) {
    diagnostics.add(
      'validation.comparison must describe with and without continuity results.',
    );
  } else {
    final comparisonMap = Map<String, dynamic>.from(comparison);
    _requireNonEmptyString(
      comparisonMap,
      'with_continuity_result',
      diagnostics,
      path: 'validation.comparison.with_continuity_result',
    );
    _requireNonEmptyString(
      comparisonMap,
      'without_continuity_result',
      diagnostics,
      path: 'validation.comparison.without_continuity_result',
    );
  }
  for (final field in ['outcome', 'falsifier', 'reviewer', 'updated_at']) {
    _requireNonEmptyString(
      validation,
      field,
      diagnostics,
      path: 'validation.$field',
    );
  }
  _requireStringList(
    validation,
    'non_claims',
    diagnostics,
    path: 'validation.non_claims',
    minItems: 1,
  );
}

void _requireExactString(
  final Map<String, dynamic> object,
  final String field,
  final String expected,
  final List<String> diagnostics,
) {
  if (object[field] != expected) {
    diagnostics.add('$field must be "$expected".');
  }
}

void _requireNonEmptyString(
  final Map<String, dynamic> object,
  final String field,
  final List<String> diagnostics, {
  final String? path,
}) {
  final value = object[field];
  if (value is! String || value.trim().isEmpty) {
    diagnostics.add('${path ?? field} must be a non-empty string.');
  }
}

void _requireStringIfPresent(
  final Map<String, dynamic> object,
  final String field,
  final List<String> diagnostics,
) {
  if (object[field] is! String) {
    diagnostics.add('$field must be a string when present.');
  }
}

void _requireEnumString(
  final Map<String, dynamic> object,
  final String field,
  final Set<String> allowed,
  final List<String> diagnostics,
) {
  final value = object[field];
  if (value is! String || !allowed.contains(value)) {
    diagnostics.add('$field must be one of: ${allowed.join(', ')}.');
  }
}

void _requireStringList(
  final Map<String, dynamic> object,
  final String field,
  final List<String> diagnostics, {
  final int minItems = 0,
  final String? path,
}) {
  final value = object[field];
  final label = path ?? field;
  if (value is! List) {
    diagnostics.add('$label must be an array of strings.');
    return;
  }
  if (value.length < minItems) {
    diagnostics.add('$label must contain at least $minItems item(s).');
  }
  for (var index = 0; index < value.length; index++) {
    if (value[index] is! String) {
      diagnostics.add('$label[$index] must be a string.');
    }
  }
}

void _requireObjectList(
  final Map<String, dynamic> object,
  final String field,
  final List<String> diagnostics, {
  required final String path,
  final int minItems = 0,
}) {
  final value = object[field];
  if (value is! List) {
    diagnostics.add('$path must be an array of objects.');
    return;
  }
  if (value.length < minItems) {
    diagnostics.add('$path must contain at least $minItems item(s).');
  }
  for (var index = 0; index < value.length; index++) {
    if (value[index] is! Map) {
      diagnostics.add('$path[$index] must be an object.');
    }
  }
}
