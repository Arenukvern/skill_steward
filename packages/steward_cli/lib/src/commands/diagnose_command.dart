import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';

import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Matches observations against promoted diagnostics only.
class DiagnoseCommand extends Command<void> {
  DiagnoseCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'from',
        mandatory: true,
        help: 'Path to a steward/observation/v1 JSON file.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'diagnose';

  @override
  final description = 'Match an observation against promoted diagnostics.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await diagnosePayload(root, argResults?['from'] as String);

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(result));
      return;
    }

    sink
      ..writeln('Steward diagnosis')
      ..writeln('- status: ${result['status']}')
      ..writeln('- known cases: ${result['known_cases']}');
  }
}

Future<Map<String, dynamic>> diagnosePayload(
  final String root,
  final String observationPath,
) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  final observation = await _readObservation(root, observationPath);
  final diagnostics = <Map<String, dynamic>>[
    ...configResult.diagnostics.map(
      (final diagnostic) => {
        'severity': diagnostic.severity,
        'path': diagnostic.path,
        'message': diagnostic.message,
      },
    ),
  ];
  final cases = _diagnosticCases(config.diagnostics, diagnostics);
  final promotedCases = cases
      .where(
        (final diagnosticCase) =>
            diagnosticCase.status == 'promoted_diagnostic',
      )
      .toList();
  final actionIds = config.actions.keys.toSet();
  final matches = <_DiagnosticMatch>[];

  for (final diagnosticCase in promotedCases) {
    final match = _matchPromotedDiagnostic(
      diagnosticCase,
      observation,
      actionIds,
    );
    if (match.diagnostics.isNotEmpty) {
      diagnostics.addAll(match.diagnostics);
    }
    if (match.matched) {
      matches.add(match);
    }
  }

  matches.sort((final a, final b) {
    final confidence = b.confidence.compareTo(a.confidence);
    if (confidence != 0) return confidence;
    return a.diagnosticId.compareTo(b.diagnosticId);
  });
  final resolvedObservationPath = resolveUnderRoot(root, observationPath);
  final observationRaw = await File(resolvedObservationPath).readAsString();
  final observationDigest = sha256
      .convert(utf8.encode(observationRaw))
      .toString();
  final relativeObservationPath = repoRelativePath(
    root,
    resolvedObservationPath,
  );

  if (matches.length > 1 && matches[0].confidence == matches[1].confidence) {
    diagnostics.add({
      'severity': 'warning',
      'path': 'diagnostics.cases',
      'message': 'ambiguous_promoted_match',
    });
    return _unknownCasePayload(
      root,
      config,
      observation,
      relativeObservationPath,
      observationDigest,
      promotedCases.length,
      diagnostics,
      matches: matches,
    );
  }

  final best = matches.isEmpty ? null : matches.first;
  if (best == null) {
    return _unknownCasePayload(
      root,
      config,
      observation,
      relativeObservationPath,
      observationDigest,
      promotedCases.length,
      diagnostics,
    );
  }

  return {
    'schema_version': 'steward.diagnose.v1',
    'root': root,
    'input_observation': _observationSummary(
      observation,
      relativeObservationPath,
      observationDigest,
    ),
    'status': 'matched',
    'diagnosis': best.diagnosis,
    'confidence': best.confidence,
    'known_cases': promotedCases.length,
    'matches': matches.map((final match) => match.summary).toList(),
    'next_probes': best.linkedActions,
    'capture': null,
    'diagnostics': diagnostics,
  };
}

Map<String, dynamic> _unknownCasePayload(
  final String root,
  final StewardConfig config,
  final Map<String, dynamic> observation,
  final String relativeObservationPath,
  final String observationDigest,
  final int knownCases,
  final List<Map<String, dynamic>> diagnostics, {
  final List<_DiagnosticMatch> matches = const [],
}) {
  final recommendedId = _recommendedUnknownCaseId(observation);
  final basePath =
      config.unknownCases['path'] as String? ?? '.steward/unknown-cases';
  return {
    'schema_version': 'steward.diagnose.v1',
    'root': root,
    'input_observation': _observationSummary(
      observation,
      relativeObservationPath,
      observationDigest,
    ),
    'status': 'unknown_case',
    'diagnosis': null,
    'confidence': 0,
    'known_cases': knownCases,
    'matches': matches.map((final match) => match.summary).toList(),
    'next_probes': _nextProbeActions(config),
    'capture': {
      'recommended': true,
      'case_id': recommendedId,
      'recommended_path': repoRelativePath(
        root,
        resolveUnderRoot(root, '$basePath/$recommendedId.json'),
      ),
      'command':
          'steward unknown-case create --from $relativeObservationPath --json',
    },
    'diagnostics': diagnostics,
  };
}

Map<String, dynamic> _observationSummary(
  final Map<String, dynamic> observation,
  final String path,
  final String digest,
) {
  final summary = Map<String, dynamic>.from(
    observation['summary'] as Map? ?? const {},
  );
  return {
    'id': observation['id'],
    'path': path,
    'sha256': digest,
    'repo': observation['repo'],
    'repo_commit': observation['repo_commit'],
    'dirty': observation['dirty'],
    'probe_id': observation['probe_id'],
    'action_id': observation['action_id'],
    'summary_status': summary['status'],
    'exit_code': observation['exit_code'],
  };
}

List<_DiagnosticCase> _diagnosticCases(
  final Map<String, dynamic> diagnostics,
  final List<Map<String, dynamic>> resultDiagnostics,
) {
  final rawCases = diagnostics['cases'];
  if (rawCases == null) {
    return const [];
  }
  if (rawCases is! Map) {
    resultDiagnostics.add({
      'severity': 'error',
      'path': 'diagnostics.cases',
      'message': 'diagnostics.cases must be a map.',
    });
    return const [];
  }
  final cases = <_DiagnosticCase>[];
  for (final entry in rawCases.entries) {
    final id = '${entry.key}';
    if (entry.value is! Map) {
      resultDiagnostics.add({
        'severity': 'error',
        'path': 'diagnostics.cases.$id',
        'message': 'Diagnostic case must be a map.',
      });
      continue;
    }
    cases.add(
      _DiagnosticCase(id, Map<String, dynamic>.from(entry.value as Map)),
    );
  }
  return cases;
}

_DiagnosticMatch _matchPromotedDiagnostic(
  final _DiagnosticCase diagnosticCase,
  final Map<String, dynamic> observation,
  final Set<String> actionIds,
) {
  final diagnostics = <Map<String, dynamic>>[];
  void addDiagnostic(final String path, final String message) {
    diagnostics.add({'severity': 'error', 'path': path, 'message': message});
  }

  final detection = diagnosticCase.detection;
  _validatePromotedDiagnostic(diagnosticCase, actionIds, addDiagnostic);
  if (diagnostics.isNotEmpty) {
    return _DiagnosticMatch.no(diagnosticCase, diagnostics);
  }

  final predicates = detection['predicates'];
  if (predicates is! List || predicates.isEmpty) {
    addDiagnostic(
      'diagnostics.cases.${diagnosticCase.id}.detection.predicates',
      'Promoted diagnostics must declare non-empty detection predicates.',
    );
    return _DiagnosticMatch.no(diagnosticCase, diagnostics);
  }
  final threshold = detection['confidence_threshold'];
  if (threshold is! num || threshold <= 0 || threshold > 1) {
    addDiagnostic(
      'diagnostics.cases.${diagnosticCase.id}.detection.confidence_threshold',
      'Promoted diagnostics must declare confidence_threshold in (0, 1].',
    );
    return _DiagnosticMatch.no(diagnosticCase, diagnostics);
  }

  final matchedPredicates = <Map<String, dynamic>>[];
  for (var index = 0; index < predicates.length; index++) {
    final predicate = predicates[index];
    final path =
        'diagnostics.cases.${diagnosticCase.id}.detection.predicates.$index';
    if (predicate is! Map) {
      addDiagnostic(path, 'Detection predicate must be a map.');
      return _DiagnosticMatch.no(diagnosticCase, diagnostics);
    }
    final result = _predicateMatches(
      Map<String, dynamic>.from(predicate),
      observation,
    );
    if (result.unsupported != null) {
      addDiagnostic(path, result.unsupported!);
      return _DiagnosticMatch.no(diagnosticCase, diagnostics);
    }
    if (!result.matched) {
      return _DiagnosticMatch.no(diagnosticCase, diagnostics);
    }
    matchedPredicates.add(result.summary);
  }

  final confidence =
      (detection['confidence'] as num?)?.toDouble() ?? threshold.toDouble();
  if (confidence < threshold) {
    return _DiagnosticMatch.no(diagnosticCase, diagnostics);
  }

  final linkedActions = diagnosticCase.linkedActions;
  if (linkedActions.isEmpty) {
    addDiagnostic(
      'diagnostics.cases.${diagnosticCase.id}.linked_actions',
      'Promoted diagnostics must declare linked action ids.',
    );
    return _DiagnosticMatch.no(diagnosticCase, diagnostics);
  }

  return _DiagnosticMatch.yes(
    diagnosticCase,
    diagnostics,
    confidence: confidence,
    matchedPredicates: matchedPredicates,
  );
}

void _validatePromotedDiagnostic(
  final _DiagnosticCase diagnosticCase,
  final Set<String> actionIds,
  final void Function(String path, String message) addDiagnostic,
) {
  final prefix = 'diagnostics.cases.${diagnosticCase.id}';
  final raw = diagnosticCase.raw;
  void requireString(final String key) {
    if ('${raw[key] ?? ''}'.trim().isEmpty) {
      addDiagnostic('$prefix.$key', '$key is required.');
    }
  }

  requireString('diagnostic_id');
  requireString('repo');
  final sourceUnknownCases = raw['source_unknown_cases'];
  if (sourceUnknownCases is! List || sourceUnknownCases.isEmpty) {
    addDiagnostic(
      '$prefix.source_unknown_cases',
      'source_unknown_cases must be non-empty.',
    );
  }
  final verification = raw['verification'];
  final heldOut = verification is Map
      ? verification['held_out_benchmarks']
      : null;
  if (heldOut is! List || heldOut.isEmpty) {
    addDiagnostic(
      '$prefix.verification.held_out_benchmarks',
      'held_out_benchmarks must be non-empty.',
    );
  }
  final review = raw['review'];
  if (review is! Map ||
      '${review['owner'] ?? ''}'.trim().isEmpty ||
      '${review['approved_by'] ?? ''}'.trim().isEmpty ||
      '${review['approved_at'] ?? ''}'.trim().isEmpty) {
    addDiagnostic(
      '$prefix.review',
      'review owner, approved_by, and approved_at are required.',
    );
  }
  final provenance = raw['provenance'];
  if (provenance is! Map ||
      '${provenance['first_seen'] ?? ''}'.trim().isEmpty ||
      '${provenance['source'] ?? ''}'.trim().isEmpty) {
    addDiagnostic(
      '$prefix.provenance',
      'provenance first_seen and source are required.',
    );
  }
  final linkedActions = diagnosticCase.linkedActions;
  if (linkedActions.isEmpty) {
    addDiagnostic(
      '$prefix.linked_actions',
      'linked_actions must be non-empty.',
    );
  }
  for (final actionId in linkedActions) {
    if (!actionIds.contains(actionId)) {
      addDiagnostic(
        '$prefix.linked_actions',
        'Linked action "$actionId" is not declared in actions.',
      );
    }
  }
}

_PredicateResult _predicateMatches(
  final Map<String, dynamic> predicate,
  final Map<String, dynamic> observation,
) {
  final kind = predicate['kind'] as String? ?? '';
  final summary = Map<String, dynamic>.from(
    observation['summary'] as Map? ?? const {},
  );
  switch (kind) {
    case 'stderr_contains':
      return _containsPredicate(
        kind,
        summary['stderr_excerpt'],
        predicate['value'],
      );
    case 'stdout_contains':
      return _containsPredicate(
        kind,
        summary['stdout_excerpt'],
        predicate['value'],
      );
    case 'status_equals':
      return _equalsPredicate(kind, summary['status'], predicate['value']);
    case 'summary_status_equals':
      return _equalsPredicate(kind, summary['status'], predicate['value']);
    case 'exit_code_equals':
      return _equalsPredicate(
        kind,
        observation['exit_code'],
        predicate['value'],
      );
    case 'action_id_equals':
      return _equalsPredicate(
        kind,
        observation['action_id'],
        predicate['value'],
      );
    case 'probe_id_equals':
      return _equalsPredicate(
        kind,
        observation['probe_id'],
        predicate['value'],
      );
    case 'artifact_digest_match':
      return _PredicateResult.unsupported(
        'artifact_digest_match is reserved for benchmark/artifact summaries.',
      );
    default:
      return _PredicateResult.unsupported(
        'Unsupported predicate kind "$kind".',
      );
  }
}

_PredicateResult _containsPredicate(
  final String kind,
  final Object? source,
  final Object? value,
) {
  final needle = value?.toString() ?? '';
  final haystack = source?.toString() ?? '';
  return _PredicateResult(
    matched: needle.isNotEmpty && haystack.contains(needle),
    summary: {'kind': kind, 'value': needle},
  );
}

_PredicateResult _equalsPredicate(
  final String kind,
  final Object? source,
  final Object? value,
) => _PredicateResult(
  matched: source == value,
  summary: {'kind': kind, 'value': value},
);

Future<Map<String, dynamic>> _readObservation(
  final String root,
  final String observationPath,
) async {
  final resolved = resolveUnderRoot(root, observationPath);
  final raw = await File(resolved).readAsString();
  final data = jsonDecode(raw);
  if (data is! Map || data['schema'] != 'steward/observation/v1') {
    throw const FormatException(
      'Input is not a steward/observation/v1 JSON file.',
    );
  }
  return Map<String, dynamic>.from(data);
}

List<String> _nextProbeActions(final StewardConfig config) {
  final quick = config.probes['quick'];
  if (quick is Map) {
    final actions = quick['actions'];
    if (actions is List) {
      return actions.whereType<String>().where((final id) {
        final raw = config.actions[id];
        if (raw is! Map) return false;
        final action = StewardAction.fromMap(
          id,
          Map<String, dynamic>.from(raw),
        );
        return action.quickPolicyViolations().isEmpty;
      }).toList();
    }
  }
  return const [];
}

String _recommendedUnknownCaseId(final Map<String, dynamic> observation) {
  final id = '${observation['id'] ?? 'observation'}'
      .replaceAll(RegExp('[^a-zA-Z0-9._-]+'), '-')
      .toLowerCase();
  return 'unknown-$id';
}

class _DiagnosticCase {
  const _DiagnosticCase(this.id, this.raw);

  final String id;
  final Map<String, dynamic> raw;

  String get status => raw['status'] as String? ?? '';

  Map<String, dynamic> get detection =>
      Map<String, dynamic>.from(raw['detection'] as Map? ?? const {});

  List<String> get linkedActions =>
      (raw['linked_actions'] as List? ?? const []).whereType<String>().toList();

  Map<String, dynamic> toDiagnosis(
    final double confidence,
    final List<Map<String, dynamic>> matchedPredicates,
  ) => {
    'diagnostic_id': raw['diagnostic_id'] ?? id,
    'status': status,
    'repo': raw['repo'],
    'source_unknown_cases': raw['source_unknown_cases'] ?? const [],
    'matched_predicates': matchedPredicates,
    'linked_actions': linkedActions,
    'verification': raw['verification'] ?? const {},
    'review': raw['review'] ?? const {},
    'provenance': raw['provenance'] ?? const {},
    'confidence': confidence,
  };
}

class _DiagnosticMatch {
  const _DiagnosticMatch._({
    required this.diagnosticCase,
    required this.diagnostics,
    required this.matched,
    required this.confidence,
    required this.matchedPredicates,
  });

  factory _DiagnosticMatch.yes(
    final _DiagnosticCase diagnosticCase,
    final List<Map<String, dynamic>> diagnostics, {
    required final double confidence,
    required final List<Map<String, dynamic>> matchedPredicates,
  }) => _DiagnosticMatch._(
    diagnosticCase: diagnosticCase,
    diagnostics: diagnostics,
    matched: true,
    confidence: confidence,
    matchedPredicates: matchedPredicates,
  );

  factory _DiagnosticMatch.no(
    final _DiagnosticCase diagnosticCase,
    final List<Map<String, dynamic>> diagnostics,
  ) => _DiagnosticMatch._(
    diagnosticCase: diagnosticCase,
    diagnostics: diagnostics,
    matched: false,
    confidence: 0,
    matchedPredicates: const [],
  );

  final _DiagnosticCase diagnosticCase;
  final List<Map<String, dynamic>> diagnostics;
  final bool matched;
  final double confidence;
  final List<Map<String, dynamic>> matchedPredicates;

  String get diagnosticId => diagnosis['diagnostic_id'] as String;

  List<String> get linkedActions => diagnosticCase.linkedActions;

  Map<String, dynamic> get diagnosis =>
      diagnosticCase.toDiagnosis(confidence, matchedPredicates);

  Map<String, dynamic> get summary => {
    'diagnostic_id': diagnosis['diagnostic_id'],
    'confidence': confidence,
    'linked_actions': linkedActions,
    'matched_predicates': matchedPredicates,
  };
}

class _PredicateResult {
  const _PredicateResult({
    required this.matched,
    required this.summary,
    this.unsupported,
  });

  factory _PredicateResult.unsupported(final String message) =>
      _PredicateResult(matched: false, summary: const {}, unsupported: message);

  final bool matched;
  final Map<String, dynamic> summary;
  final String? unsupported;
}
