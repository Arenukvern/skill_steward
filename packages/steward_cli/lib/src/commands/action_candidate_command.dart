import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Groups append-only action-candidate review records.
class ActionCandidateCommand extends Command<void> {
  ActionCandidateCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(ActionCandidateCreateCommand(outputSink, startDirectory));
    addSubcommand(ActionCandidateInspectCommand(outputSink, startDirectory));
    addSubcommand(ActionCandidateReviewCommand(outputSink, startDirectory));
  }

  @override
  final name = 'action-candidate';

  @override
  final description = 'Create append-only pending action-candidate records.';
}

class ActionCandidateInspectCommand extends Command<void> {
  ActionCandidateInspectCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'inspect';

  @override
  final description = 'Inspect one pending action-candidate record by path.';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.length != 1) {
      throw UsageException(
        'Usage: steward action-candidate inspect <path>',
        usage,
      );
    }

    final root = findRepoRoot(startDirectory ?? Directory.current);
    final record = await inspectActionCandidatePayload(root, rest.single);

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(record));
      return;
    }

    sink
      ..writeln('Action candidate')
      ..writeln('- id: ${record['candidate_id']}')
      ..writeln(
        '- review: ${(record['review'] as Map<String, dynamic>)['status']}',
      );
  }
}

class ActionCandidateCreateCommand extends Command<void> {
  ActionCandidateCreateCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'from',
        mandatory: true,
        help: 'Path to a steward/unknown-case/v1 JSON file.',
      )
      ..addOption('id', mandatory: true, help: 'Proposed action id.')
      ..addOption('desc', mandatory: true, help: 'Proposed action description.')
      ..addOption(
        'argv-json',
        mandatory: true,
        help: 'JSON array of command argv strings.',
      )
      ..addOption('cwd', defaultsTo: '.', help: 'Action working directory.')
      ..addOption(
        'owner',
        help: 'Review owner. Defaults to repo id from steward.yaml.',
      )
      ..addOption(
        'safety-class',
        defaultsTo: 'bounded_local',
        allowed: const [
          'observe',
          'bounded_local',
          'repo_mutation',
          'external',
        ],
        help: 'Proposed safety class. destructive candidates are not accepted.',
      )
      ..addOption(
        'timeout-ms',
        defaultsTo: '30000',
        help: 'Proposed timeout in milliseconds.',
      )
      ..addOption(
        'max-output-bytes',
        defaultsTo: '100000',
        help: 'Proposed output cap in bytes.',
      )
      ..addMultiOption(
        'fs-read',
        defaultsTo: const ['.'],
        help: 'Filesystem read glob. May be repeated.',
      )
      ..addMultiOption(
        'fs-write',
        help: 'Filesystem write glob. May be repeated.',
      )
      ..addOption(
        'git',
        defaultsTo: 'read',
        allowed: const ['false', 'read', 'write'],
        help: 'Declared git effect.',
      )
      ..addFlag('network', negatable: false, help: 'Declare network effect.')
      ..addFlag(
        'secrets',
        negatable: false,
        help: 'Declare secret access effect.',
      )
      ..addOption(
        'benchmark',
        mandatory: true,
        help: 'Required benchmark id for future promotion.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'create';

  @override
  final description = 'Create an action-candidate record from an unknown case.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final record = await createActionCandidatePayload(
      root,
      unknownCasePath: argResults?['from'] as String,
      proposedActionId: argResults?['id'] as String,
      desc: argResults?['desc'] as String,
      argvJson: argResults?['argv-json'] as String,
      cwd: argResults?['cwd'] as String? ?? '.',
      owner: argResults?['owner'] as String?,
      safetyClass: argResults?['safety-class'] as String? ?? 'bounded_local',
      timeoutMs: _parsePositiveInt(
        argResults?['timeout-ms'] as String? ?? '30000',
        'timeout-ms',
      ),
      maxOutputBytes: _parsePositiveInt(
        argResults?['max-output-bytes'] as String? ?? '100000',
        'max-output-bytes',
      ),
      fsRead: (argResults?['fs-read'] as List?)?.cast<String>() ?? const ['.'],
      fsWrite: (argResults?['fs-write'] as List?)?.cast<String>() ?? const [],
      git: argResults?['git'] as String? ?? 'read',
      network: argResults?['network'] == true,
      secrets: argResults?['secrets'] == true,
      benchmark: argResults?['benchmark'] as String,
    );

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(record));
      return;
    }

    sink
      ..writeln('Action candidate')
      ..writeln('- id: ${record['candidate_id']}')
      ..writeln('- path: ${record['path']}');
  }
}

class ActionCandidateReviewCommand extends Command<void> {
  ActionCandidateReviewCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'from',
        mandatory: true,
        help: 'Path to a steward/action-candidate/v1 JSON file.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'review';

  @override
  final description = 'Validate an action-candidate without promoting it.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final record = await reviewActionCandidatePayload(
      root,
      argResults?['from'] as String,
    );

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(record));
      return;
    }

    sink
      ..writeln('Action candidate review')
      ..writeln('- candidate: ${record['candidate_id']}')
      ..writeln('- status: ${record['status']}');
  }
}

Future<Map<String, dynamic>> createActionCandidatePayload(
  final String root, {
  required final String unknownCasePath,
  required final String proposedActionId,
  required final String desc,
  required final String argvJson,
  required final String cwd,
  required final String? owner,
  required final String safetyClass,
  required final int timeoutMs,
  required final int maxOutputBytes,
  required final List<String> fsRead,
  required final List<String> fsWrite,
  required final String git,
  required final bool network,
  required final bool secrets,
  required final String benchmark,
}) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  _validateProposedActionId(proposedActionId);
  if (config.actions.containsKey(proposedActionId)) {
    throw ArgumentError('Action "$proposedActionId" is already declared.');
  }
  final argv = _parseArgv(argvJson);
  resolveUnderRoot(root, cwd);
  final unknownCase = await _readUnknownCase(root, unknownCasePath);
  final resolvedUnknownPath = resolveUnderRoot(root, unknownCasePath);
  final unknownRaw = await File(resolvedUnknownPath).readAsString();
  final unknownDigest = sha256.convert(utf8.encode(unknownRaw)).toString();
  final createdAt = DateTime.now().toUtc();
  final candidateId = _recordId(
    'action-candidate',
    proposedActionId,
    createdAt,
  );
  final allocation = _allocateRecordPath(
    root,
    p.join('.steward', 'action-candidates'),
    candidateId,
  );
  final defaultPolicy =
      safetyClass == 'observe' || safetyClass == 'bounded_local'
      ? 'auto'
      : 'confirm';
  final proposedAction = {
    'id': proposedActionId,
    'kind': 'command',
    'desc': desc,
    'command': {'argv': argv, 'shell': false},
    'cwd': cwd,
    'effects': {
      'fs_read': fsRead,
      'fs_write': fsWrite,
      'git': git == 'false' ? false : git,
      'network': network,
      'secrets': secrets,
      'destructive': false,
    },
    'safety': {
      'class': safetyClass,
      'default_policy': defaultPolicy,
      'requires_confirmation': defaultPolicy != 'auto',
    },
    'limits': {'timeout_ms': timeoutMs, 'max_output_bytes': maxOutputBytes},
    'outputs': [
      {
        'id': 'stdout',
        'kind': 'stream',
        'required': true,
        'retention': 'summary',
      },
    ],
    'evidence': {'redaction': 'steward/redaction/v1'},
  };
  final record = {
    'schema': 'steward/action-candidate/v1',
    'candidate_id': allocation.id,
    'status': 'action_candidate',
    'repo': config.repo['id'] ?? unknownCase['repo'],
    'repo_commit': unknownCase['repo_commit'],
    'dirty': unknownCase['dirty'],
    'created_at': createdAt.toIso8601String(),
    'source_unknown_cases': [
      {
        'id': unknownCase['id'],
        'path': repoRelativePath(root, resolvedUnknownPath),
        'sha256': unknownDigest,
      },
    ],
    'proposed_action': proposedAction,
    'review': {
      'owner': owner ?? config.repo['id'] ?? unknownCase['repo'],
      'status': 'pending',
      'promoted': false,
    },
    'promotion_gate': {
      'required_validation': 'steward action inspect $proposedActionId --json',
      'required_benchmark': benchmark,
      'required_review': true,
      'can_promote_in_this_run': false,
    },
    'retention': 'local',
  };

  final targetFile = File(allocation.path)..parent.createSync(recursive: true);
  if (targetFile.existsSync()) {
    throw StateError(
      'Action-candidate record already exists: ${allocation.id}',
    );
  }
  await targetFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
    mode: FileMode.writeOnly,
  );

  return {...record, 'path': repoRelativePath(root, allocation.path)};
}

Future<Map<String, dynamic>> reviewActionCandidatePayload(
  final String root,
  final String candidatePath,
) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  final candidate = await _readActionCandidate(root, candidatePath);
  final diagnostics = <Map<String, dynamic>>[];

  void addDiagnostic(final String path, final String message) {
    diagnostics.add({'severity': 'error', 'path': path, 'message': message});
  }

  if (candidate['status'] != 'action_candidate') {
    addDiagnostic('status', 'Candidate status must be action_candidate.');
  }

  final proposedAction = Map<String, dynamic>.from(
    candidate['proposed_action'] as Map? ?? const {},
  );
  final actionId = proposedAction['id'] as String? ?? '';
  try {
    _validateProposedActionId(actionId);
  } on Object catch (error) {
    addDiagnostic('proposed_action.id', '$error');
  }
  if (config.actions.containsKey(actionId)) {
    addDiagnostic(
      'proposed_action.id',
      'Action "$actionId" is already declared in steward.yaml.',
    );
  }
  _validateProposedActionShape(root, proposedAction, addDiagnostic);

  final sourceCases = candidate['source_unknown_cases'];
  if (sourceCases is! List || sourceCases.isEmpty) {
    addDiagnostic(
      'source_unknown_cases',
      'Candidate must reference at least one unknown case.',
    );
  } else {
    for (var index = 0; index < sourceCases.length; index++) {
      final source = sourceCases[index];
      if (source is! Map) {
        addDiagnostic(
          'source_unknown_cases.$index',
          'Source unknown case must be a map.',
        );
        continue;
      }
      final path = source['path'] as String?;
      if (path == null || path.trim().isEmpty) {
        addDiagnostic(
          'source_unknown_cases.$index.path',
          'Source unknown case path is required.',
        );
        continue;
      }
      try {
        final unknown = await _readUnknownCase(root, path);
        final repo = candidate['repo'];
        if (repo != null && unknown['repo'] != repo) {
          addDiagnostic(
            'source_unknown_cases.$index.repo',
            'Source unknown case repo does not match candidate repo.',
          );
        }
      } on Object catch (error) {
        addDiagnostic('source_unknown_cases.$index.path', '$error');
      }
    }
  }

  final review = candidate['review'];
  if (review is! Map || '${review['owner'] ?? ''}'.trim().isEmpty) {
    addDiagnostic('review.owner', 'Review owner is required.');
  }
  if (review is! Map || review['status'] != 'pending') {
    addDiagnostic('review.status', 'Review status must remain pending.');
  }
  if (review is Map && review.containsKey('approved_by')) {
    addDiagnostic(
      'review.approved_by',
      'Candidate creation cannot approve itself.',
    );
  }

  final gate = candidate['promotion_gate'];
  if (gate is! Map) {
    addDiagnostic('promotion_gate', 'Promotion gate is required.');
  } else {
    final expectedValidation = 'steward action inspect $actionId --json';
    if (gate['required_validation'] != expectedValidation) {
      addDiagnostic(
        'promotion_gate.required_validation',
        'Required validation must be "$expectedValidation".',
      );
    }
    if ('${gate['required_benchmark'] ?? ''}'.trim().isEmpty) {
      addDiagnostic(
        'promotion_gate.required_benchmark',
        'Required benchmark id is required.',
      );
    }
    if (gate['can_promote_in_this_run'] != false) {
      addDiagnostic(
        'promotion_gate.can_promote_in_this_run',
        'A dogfood run cannot promote an action it proposed.',
      );
    }
  }

  return {
    'schema_version': 'steward.action_candidate.review.v1',
    'candidate_id': candidate['candidate_id'],
    'status': diagnostics.isEmpty ? 'passed' : 'failed',
    'promotable': false,
    'diagnostics': diagnostics,
    'promotion_gate': candidate['promotion_gate'],
  };
}

Future<Map<String, dynamic>> inspectActionCandidatePayload(
  final String root,
  final String candidatePath,
) async {
  final record = await _readActionCandidate(root, candidatePath);
  final proposed = Map<String, dynamic>.from(
    record['proposed_action'] as Map? ?? const {},
  );
  final actionId = proposed['id'] as String? ?? '';
  final action = StewardAction.fromMap(actionId, proposed);
  return {
    'schema_version': 'steward.action-candidate-inspect.v1',
    'root': root,
    'candidate': record,
    'proposed_action': action.toJson(),
    'validation': {
      'registered': false,
      'review_status': (record['review'] as Map?)?['status'],
      'can_promote_in_this_run': false,
      'quick_policy_violations': action.quickPolicyViolations(),
    },
  };
}

Future<Map<String, dynamic>> _readUnknownCase(
  final String root,
  final String unknownCasePath,
) async {
  final resolved = resolveUnderRoot(root, unknownCasePath);
  final raw = await File(resolved).readAsString();
  final data = jsonDecode(raw);
  if (data is! Map || data['schema'] != 'steward/unknown-case/v1') {
    throw const FormatException(
      'Input is not a steward/unknown-case/v1 JSON file.',
    );
  }
  return Map<String, dynamic>.from(data);
}

Future<Map<String, dynamic>> _readActionCandidate(
  final String root,
  final String candidatePath,
) async {
  final resolved = resolveUnderRoot(root, candidatePath);
  final raw = await File(resolved).readAsString();
  final data = jsonDecode(raw);
  if (data is! Map || data['schema'] != 'steward/action-candidate/v1') {
    throw const FormatException(
      'Input is not a steward/action-candidate/v1 JSON file.',
    );
  }
  return Map<String, dynamic>.from(data);
}

List<String> _parseArgv(final String argvJson) {
  final decoded = jsonDecode(argvJson);
  if (decoded is! List ||
      decoded.isEmpty ||
      decoded.any((final item) => item is! String)) {
    throw const FormatException(
      'argv-json must be a non-empty JSON string list.',
    );
  }
  return decoded.cast<String>();
}

int _parsePositiveInt(final String value, final String name) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 1) {
    throw FormatException('$name must be a positive integer.');
  }
  return parsed;
}

void _validateProposedActionId(final String actionId) {
  final pattern = RegExp(r'^[a-z][a-z0-9._-]*$');
  if (!pattern.hasMatch(actionId)) {
    throw ArgumentError(
      r'Action ids must match ^[a-z][a-z0-9._-]*$ for stable references.',
    );
  }
}

void _validateProposedActionShape(
  final String root,
  final Map<String, dynamic> action,
  final void Function(String path, String message) addDiagnostic,
) {
  if (action['kind'] != 'command') {
    addDiagnostic('proposed_action.kind', 'Only kind: command is supported.');
  }
  if ('${action['desc'] ?? ''}'.trim().isEmpty) {
    addDiagnostic('proposed_action.desc', 'Action description is required.');
  }
  final cwd = action['cwd'];
  if (cwd is! String || cwd.trim().isEmpty) {
    addDiagnostic('proposed_action.cwd', 'Action cwd is required.');
  } else {
    try {
      resolveUnderRoot(root, cwd);
    } on Object catch (error) {
      addDiagnostic('proposed_action.cwd', '$error');
    }
  }
  final command = action['command'];
  if (command is! Map) {
    addDiagnostic('proposed_action.command', 'Command map is required.');
  } else {
    final argv = command['argv'];
    if (argv is! List ||
        argv.isEmpty ||
        argv.any((final item) => item is! String)) {
      addDiagnostic(
        'proposed_action.command.argv',
        'command.argv must be a non-empty list of strings.',
      );
    }
    if (command['shell'] is! bool) {
      addDiagnostic(
        'proposed_action.command.shell',
        'command.shell must be a boolean.',
      );
    }
  }
  for (final key in ['effects', 'safety', 'limits', 'outputs', 'evidence']) {
    if (action[key] is! Map && action[key] is! List) {
      addDiagnostic('proposed_action.$key', '$key must be a map or list.');
    }
  }
  final limitsValue = action['limits'];
  if (limitsValue is Map) {
    final limits = Map<String, dynamic>.from(limitsValue);
    final timeoutMs = limits['timeout_ms'];
    final maxOutputBytes = limits['max_output_bytes'];
    if (timeoutMs is! int || timeoutMs < 1) {
      addDiagnostic(
        'proposed_action.limits.timeout_ms',
        'timeout_ms must be a positive integer.',
      );
    }
    if (maxOutputBytes is! int || maxOutputBytes < 1) {
      addDiagnostic(
        'proposed_action.limits.max_output_bytes',
        'max_output_bytes must be a positive integer.',
      );
    }
  }
  final effects = action['effects'];
  if (effects is Map) {
    _validateProposedActionEffects(
      root,
      Map<String, dynamic>.from(effects),
      addDiagnostic,
    );
  }
}

void _validateProposedActionEffects(
  final String root,
  final Map<String, dynamic> effects,
  final void Function(String path, String message) addDiagnostic,
) {
  final fsWrite = effects['fs_write'];
  if (fsWrite == null) {
    return;
  }
  if (fsWrite is! List || fsWrite.any((final item) => item is! String)) {
    addDiagnostic(
      'proposed_action.effects.fs_write',
      'fs_write must be a list of repository-relative globs.',
    );
    return;
  }
  for (var index = 0; index < fsWrite.length; index++) {
    final glob = fsWrite[index] as String;
    final path = 'proposed_action.effects.fs_write.$index';
    if (!_isAllowedArtifactWriteGlob(root, glob)) {
      addDiagnostic(
        path,
        'Action-candidate writes must stay under .steward/artifacts or .steward/observations.',
      );
    }
  }
}

bool _isAllowedArtifactWriteGlob(final String root, final String glob) {
  final trimmed = glob.trim();
  if (trimmed.isEmpty || trimmed.startsWith('~')) {
    return false;
  }
  final normalized = p.normalize(trimmed).replaceAll(r'\', '/');
  if (normalized == '..' || normalized.startsWith('../')) {
    return false;
  }
  try {
    resolveUnderRoot(root, normalized);
  } on Object {
    return false;
  }
  return normalized == '.steward/artifacts' ||
      normalized == '.steward/observations' ||
      normalized.startsWith('.steward/artifacts/') ||
      normalized.startsWith('.steward/observations/');
}

String _recordId(
  final String prefix,
  final String actionId,
  final DateTime timestamp,
) {
  final compact = timestamp
      .toIso8601String()
      .replaceAll(RegExp('[^0-9A-Za-z]+'), '')
      .toLowerCase();
  final safeActionId = actionId.replaceAll(RegExp('[^a-z0-9._-]+'), '-');
  return '$prefix-$safeActionId-$compact';
}

_RecordAllocation _allocateRecordPath(
  final String root,
  final String relativeDir,
  final String baseId,
) {
  for (var index = 0; index < 1000; index++) {
    final id = index == 0
        ? baseId
        : '$baseId-${index.toString().padLeft(3, '0')}';
    final candidate = resolveUnderRoot(root, p.join(relativeDir, '$id.json'));
    if (!File(candidate).existsSync()) {
      return _RecordAllocation(id, candidate);
    }
  }
  throw StateError(
    'Could not allocate a unique action-candidate id for $baseId.',
  );
}

class _RecordAllocation {
  const _RecordAllocation(this.id, this.path);

  final String id;
  final String path;
}
