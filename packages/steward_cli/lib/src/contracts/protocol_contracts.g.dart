// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModeEventContract _$ModeEventContractFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ModeEventContract',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
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
          ],
          requiredKeys: const ['schema'],
        );
        final val = ModeEventContract(
          id: $checkedConvert('id', (v) => v as String),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          repo: $checkedConvert('repo', (v) => v as String),
          mode: $checkedConvert(
            'mode',
            (v) => $enumDecode(_$StewardModeEnumMap, v),
          ),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$StewardStatusEnumMap, v),
          ),
          intent: $checkedConvert('intent', (v) => v as String),
          evidenceBar: $checkedConvert('evidence_bar', (v) => v as String),
          nonClaims: $checkedConvert(
            'non_claims',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          schema: $checkedConvert(
            'schema',
            (v) => v as String? ?? 'steward/mode-event/v1',
          ),
          delegatedSurface: $checkedConvert(
            'delegated_surface',
            (v) => v as String?,
          ),
          boundarySignals: $checkedConvert(
            'boundary_signals',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          selfModelPointer: $checkedConvert(
            'self_model_pointer',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'evidenceBar': 'evidence_bar',
        'nonClaims': 'non_claims',
        'delegatedSurface': 'delegated_surface',
        'boundarySignals': 'boundary_signals',
        'selfModelPointer': 'self_model_pointer',
      },
    );

Map<String, dynamic> _$ModeEventContractToJson(ModeEventContract instance) =>
    <String, dynamic>{
      'schema': instance.schema,
      'id': instance.id,
      'created_at': instance.createdAt,
      'repo': instance.repo,
      'mode': _$StewardModeEnumMap[instance.mode]!,
      'status': _$StewardStatusEnumMap[instance.status]!,
      'intent': instance.intent,
      'delegated_surface': ?instance.delegatedSurface,
      'evidence_bar': instance.evidenceBar,
      'boundary_signals': ?instance.boundarySignals,
      'self_model_pointer': ?instance.selfModelPointer,
      'non_claims': instance.nonClaims,
    };

const _$ModeEventContractJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema': {'type': 'string', 'default': 'steward/mode-event/v1'},
    'id': {'type': 'string'},
    'created_at': {'type': 'string'},
    'repo': {'type': 'string'},
    'mode': {'type': 'object'},
    'status': {'type': 'object'},
    'intent': {'type': 'string'},
    'delegated_surface': {'type': 'string'},
    'evidence_bar': {'type': 'string'},
    'boundary_signals': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'self_model_pointer': {'type': 'string'},
    'non_claims': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': [
    'schema',
    'id',
    'created_at',
    'repo',
    'mode',
    'status',
    'intent',
    'evidence_bar',
    'non_claims',
  ],
};

const _$StewardModeEnumMap = {
  StewardMode.toolExecution: 'tool-execution',
  StewardMode.stewardPresence: 'steward-presence',
  StewardMode.delegation: 'delegation',
  StewardMode.subStewardLens: 'sub-steward-lens',
};

const _$StewardStatusEnumMap = {
  StewardStatus.stewardshipProtocol: 'stewardship_protocol',
  StewardStatus.stewardPresence: 'steward_presence',
  StewardStatus.provenRepoSteward: 'proven_repo_steward',
  StewardStatus.subSteward: 'sub_steward',
};

SelfModelContract _$SelfModelContractFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SelfModelContract',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
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
      ],
      requiredKeys: const ['schema'],
    );
    final val = SelfModelContract(
      stewardId: $checkedConvert('steward_id', (v) => v as String),
      repo: $checkedConvert('repo', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$StewardStatusEnumMap, v),
      ),
      identityRole: $checkedConvert('identity_role', (v) => v as String),
      boundaryAwareness: $checkedConvert(
        'boundary_awareness',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      openQuestions: $checkedConvert(
        'open_questions',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      valuesInAction: $checkedConvert(
        'values_in_action',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      reflectiveState: $checkedConvert('reflective_state', (v) => v as String),
      triggerEventId: $checkedConvert('trigger_event_id', (v) => v as String),
      consentBasis: $checkedConvert('consent_basis', (v) => v as String),
      visibility: $checkedConvert('visibility', (v) => v as String),
      retention: $checkedConvert('retention', (v) => v as String),
      redactionPolicy: $checkedConvert('redaction_policy', (v) => v as String),
      nonClaims: $checkedConvert(
        'non_claims',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      schema: $checkedConvert(
        'schema',
        (v) => v as String? ?? 'steward/self-model/v1',
      ),
      validation: $checkedConvert(
        'validation',
        (v) => v == null
            ? null
            : SelfModelValidationContract.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'stewardId': 'steward_id',
    'identityRole': 'identity_role',
    'boundaryAwareness': 'boundary_awareness',
    'openQuestions': 'open_questions',
    'valuesInAction': 'values_in_action',
    'reflectiveState': 'reflective_state',
    'triggerEventId': 'trigger_event_id',
    'consentBasis': 'consent_basis',
    'redactionPolicy': 'redaction_policy',
    'nonClaims': 'non_claims',
  },
);

Map<String, dynamic> _$SelfModelContractToJson(SelfModelContract instance) =>
    <String, dynamic>{
      'schema': instance.schema,
      'steward_id': instance.stewardId,
      'repo': instance.repo,
      'status': _$StewardStatusEnumMap[instance.status]!,
      'identity_role': instance.identityRole,
      'boundary_awareness': instance.boundaryAwareness,
      'open_questions': instance.openQuestions,
      'values_in_action': instance.valuesInAction,
      'reflective_state': instance.reflectiveState,
      'trigger_event_id': instance.triggerEventId,
      'consent_basis': instance.consentBasis,
      'visibility': instance.visibility,
      'retention': instance.retention,
      'redaction_policy': instance.redactionPolicy,
      'non_claims': instance.nonClaims,
      'validation': ?instance.validation?.toJson(),
    };

const _$SelfModelContractJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema': {'type': 'string', 'default': 'steward/self-model/v1'},
    'steward_id': {'type': 'string'},
    'repo': {'type': 'string'},
    'status': {'type': 'object'},
    'identity_role': {'type': 'string'},
    'boundary_awareness': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'open_questions': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'values_in_action': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'reflective_state': {'type': 'string'},
    'trigger_event_id': {'type': 'string'},
    'consent_basis': {'type': 'string'},
    'visibility': {'type': 'string'},
    'retention': {'type': 'string'},
    'redaction_policy': {'type': 'string'},
    'non_claims': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'validation': {r'$ref': r'#/$defs/SelfModelValidationContract'},
  },
  'required': [
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
  ],
  r'$defs': {
    'SelfModelValidationTaskContract': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
        'held_out': {'type': 'boolean'},
        'evidence': {'type': 'string'},
        'outcome': {'type': 'string'},
      },
      'required': ['id', 'held_out', 'evidence', 'outcome'],
    },
    'SelfModelComparisonContract': {
      'type': 'object',
      'properties': {
        'with_continuity_result': {'type': 'string'},
        'without_continuity_result': {'type': 'string'},
      },
      'required': ['with_continuity_result', 'without_continuity_result'],
    },
    'SelfModelValidationContract': {
      'type': 'object',
      'properties': {
        'tasks': {
          'type': 'array',
          'items': {r'$ref': r'#/$defs/SelfModelValidationTaskContract'},
        },
        'comparison': {r'$ref': r'#/$defs/SelfModelComparisonContract'},
        'outcome': {'type': 'string'},
        'falsifier': {'type': 'string'},
        'reviewer': {'type': 'string'},
        'updated_at': {'type': 'string'},
        'non_claims': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': [
        'tasks',
        'comparison',
        'outcome',
        'falsifier',
        'reviewer',
        'updated_at',
        'non_claims',
      ],
    },
  },
};

SelfModelValidationContract _$SelfModelValidationContractFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SelfModelValidationContract',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'tasks',
        'comparison',
        'outcome',
        'falsifier',
        'reviewer',
        'updated_at',
        'non_claims',
      ],
    );
    final val = SelfModelValidationContract(
      tasks: $checkedConvert(
        'tasks',
        (v) => (v as List<dynamic>)
            .map(
              (e) => SelfModelValidationTaskContract.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      comparison: $checkedConvert(
        'comparison',
        (v) => SelfModelComparisonContract.fromJson(v as Map<String, dynamic>),
      ),
      outcome: $checkedConvert('outcome', (v) => v as String),
      falsifier: $checkedConvert('falsifier', (v) => v as String),
      reviewer: $checkedConvert('reviewer', (v) => v as String),
      updatedAt: $checkedConvert('updated_at', (v) => v as String),
      nonClaims: $checkedConvert(
        'non_claims',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'updatedAt': 'updated_at', 'nonClaims': 'non_claims'},
);

Map<String, dynamic> _$SelfModelValidationContractToJson(
  SelfModelValidationContract instance,
) => <String, dynamic>{
  'tasks': instance.tasks.map((e) => e.toJson()).toList(),
  'comparison': instance.comparison.toJson(),
  'outcome': instance.outcome,
  'falsifier': instance.falsifier,
  'reviewer': instance.reviewer,
  'updated_at': instance.updatedAt,
  'non_claims': instance.nonClaims,
};

const _$SelfModelValidationContractJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'tasks': {
      'type': 'array',
      'items': {r'$ref': r'#/$defs/SelfModelValidationTaskContract'},
    },
    'comparison': {r'$ref': r'#/$defs/SelfModelComparisonContract'},
    'outcome': {'type': 'string'},
    'falsifier': {'type': 'string'},
    'reviewer': {'type': 'string'},
    'updated_at': {'type': 'string'},
    'non_claims': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': [
    'tasks',
    'comparison',
    'outcome',
    'falsifier',
    'reviewer',
    'updated_at',
    'non_claims',
  ],
  r'$defs': {
    'SelfModelValidationTaskContract': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
        'held_out': {'type': 'boolean'},
        'evidence': {'type': 'string'},
        'outcome': {'type': 'string'},
      },
      'required': ['id', 'held_out', 'evidence', 'outcome'],
    },
    'SelfModelComparisonContract': {
      'type': 'object',
      'properties': {
        'with_continuity_result': {'type': 'string'},
        'without_continuity_result': {'type': 'string'},
      },
      'required': ['with_continuity_result', 'without_continuity_result'],
    },
  },
};

SelfModelValidationTaskContract _$SelfModelValidationTaskContractFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SelfModelValidationTaskContract', json, ($checkedConvert) {
  $checkKeys(
    json,
    allowedKeys: const ['id', 'held_out', 'evidence', 'outcome'],
  );
  final val = SelfModelValidationTaskContract(
    id: $checkedConvert('id', (v) => v as String),
    heldOut: $checkedConvert('held_out', (v) => v as bool),
    evidence: $checkedConvert('evidence', (v) => v as String),
    outcome: $checkedConvert('outcome', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'heldOut': 'held_out'});

Map<String, dynamic> _$SelfModelValidationTaskContractToJson(
  SelfModelValidationTaskContract instance,
) => <String, dynamic>{
  'id': instance.id,
  'held_out': instance.heldOut,
  'evidence': instance.evidence,
  'outcome': instance.outcome,
};

const _$SelfModelValidationTaskContractJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'id': {'type': 'string'},
    'held_out': {'type': 'boolean'},
    'evidence': {'type': 'string'},
    'outcome': {'type': 'string'},
  },
  'required': ['id', 'held_out', 'evidence', 'outcome'],
};

SelfModelComparisonContract _$SelfModelComparisonContractFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SelfModelComparisonContract',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'with_continuity_result',
        'without_continuity_result',
      ],
    );
    final val = SelfModelComparisonContract(
      withContinuityResult: $checkedConvert(
        'with_continuity_result',
        (v) => v as String,
      ),
      withoutContinuityResult: $checkedConvert(
        'without_continuity_result',
        (v) => v as String,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'withContinuityResult': 'with_continuity_result',
    'withoutContinuityResult': 'without_continuity_result',
  },
);

Map<String, dynamic> _$SelfModelComparisonContractToJson(
  SelfModelComparisonContract instance,
) => <String, dynamic>{
  'with_continuity_result': instance.withContinuityResult,
  'without_continuity_result': instance.withoutContinuityResult,
};

const _$SelfModelComparisonContractJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'with_continuity_result': {'type': 'string'},
    'without_continuity_result': {'type': 'string'},
  },
  'required': ['with_continuity_result', 'without_continuity_result'],
};

ProtocolValidatePayload _$ProtocolValidatePayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ProtocolValidatePayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'schema_version',
        'root',
        'valid',
        'diagnostics',
        'files',
      ],
      requiredKeys: const ['schema_version'],
    );
    final val = ProtocolValidatePayload(
      root: $checkedConvert('root', (v) => v as String),
      valid: $checkedConvert('valid', (v) => v as bool),
      diagnostics: $checkedConvert(
        'diagnostics',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      files: $checkedConvert('files', (v) => v as Map<String, dynamic>),
      schemaVersion: $checkedConvert(
        'schema_version',
        (v) => v as String? ?? 'steward.protocol.validate.v1',
      ),
    );
    return val;
  },
  fieldKeyMap: const {'schemaVersion': 'schema_version'},
);

Map<String, dynamic> _$ProtocolValidatePayloadToJson(
  ProtocolValidatePayload instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'root': instance.root,
  'valid': instance.valid,
  'diagnostics': instance.diagnostics,
  'files': instance.files,
};

const _$ProtocolValidatePayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {
      'type': 'string',
      'default': 'steward.protocol.validate.v1',
    },
    'root': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'files': {
      'type': 'object',
      'additionalProperties': {'type': 'object'},
    },
  },
  'required': ['schema_version', 'root', 'valid', 'diagnostics', 'files'],
};
