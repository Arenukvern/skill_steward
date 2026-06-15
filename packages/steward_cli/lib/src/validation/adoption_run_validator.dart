import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../yaml_utils.dart';

/// Validates committed adoption-run/v2 evidence records.
///
/// JSON Schema owns portable shape. This validator owns cross-field governance
/// checks that prevent tool-loop drift and over-strong S5/H5 claims.
Future<List<String>> validateAdoptionRunEvidence(final String rootPath) async {
  final evidenceDir = Directory(p.join(rootPath, 'docs', 'evidence'));
  if (!evidenceDir.existsSync()) return const [];

  final diagnostics = <String>[];
  final files = await evidenceDir
      .list(recursive: true, followLinks: false)
      .where((final entity) => entity is File)
      .cast<File>()
      .toList();
  files.sort((final a, final b) => a.path.compareTo(b.path));

  for (final file in files) {
    final relPath = p.relative(file.path, from: rootPath).replaceAll(r'\', '/');
    if (!_isSupportedEvidenceFile(relPath)) continue;

    String raw;
    try {
      raw = await file.readAsString();
    } on Object {
      continue;
    }

    for (final document in _extractAdoptionRunDocuments(raw, relPath)) {
      try {
        final parsed = yamlToDart(loadYaml(document.yaml));
        if (parsed is! Map<String, dynamic>) {
          diagnostics.add(
            '${document.label}: adoption-run record must be a map.',
          );
          continue;
        }
        _validateRecord(parsed, document.label, diagnostics);
      } on YamlException catch (error) {
        diagnostics.add(
          '${document.label}: invalid adoption-run YAML: ${error.message}',
        );
      } on Object catch (error) {
        diagnostics.add(
          '${document.label}: invalid adoption-run record: $error',
        );
      }
    }
  }

  return diagnostics;
}

bool _isSupportedEvidenceFile(final String path) {
  final ext = p.extension(path).toLowerCase();
  return ext == '.mdx' || ext == '.md' || ext == '.yaml' || ext == '.yml';
}

List<({String label, String yaml})> _extractAdoptionRunDocuments(
  final String raw,
  final String relPath,
) {
  if (!_containsAdoptionRunSchema(raw)) return const [];

  final ext = p.extension(relPath).toLowerCase();
  if (ext == '.yaml' || ext == '.yml') {
    return [(label: relPath, yaml: raw)];
  }

  final documents = <({String label, String yaml})>[];
  final lines = raw.split('\n');
  var inFence = false;
  var fenceInfo = '';
  var fenceStartLine = 0;
  final buffer = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      if (inFence) {
        final yaml = buffer.join('\n');
        if (_isYamlFence(fenceInfo) && _containsAdoptionRunSchema(yaml)) {
          documents.add((label: '$relPath:$fenceStartLine', yaml: yaml));
        }
        inFence = false;
        fenceInfo = '';
        buffer.clear();
      } else {
        inFence = true;
        fenceInfo = trimmed.substring(3).trim().toLowerCase();
        fenceStartLine = i + 2;
      }
      continue;
    }

    if (inFence) {
      buffer.add(line);
    }
  }

  return documents;
}

bool _isYamlFence(final String fenceInfo) =>
    fenceInfo == 'yaml' || fenceInfo == 'yml';

bool _containsAdoptionRunSchema(final String raw) => RegExp(
  r'(^|\n)\s*schema:\s*steward/adoption-run/v2\s*(\n|$)',
).hasMatch(raw);

const _productImpactLinePrefixes = [
  'runtime_behavior:',
  'public_api:',
  'product_native_gate:',
  'visual_capture:',
  'performance_metric:',
  'release_path:',
  'developer_workflow:',
  'command_output:',
  'plugin_install:',
  'support_only:',
];

void _validateRecord(
  final Map<String, dynamic> record,
  final String label,
  final List<String> diagnostics,
) {
  _validateRequiredSections(record, label, diagnostics);

  final toolDetour = _mapValue(record, 'tool_detour');
  final outcome = _mapValue(record, 'outcome');
  final promotion = _mapValue(record, 'promotion');
  final capability = _mapValue(record, 'capability');
  final directProblemPath = _mapValue(record, 'direct_problem_path');
  final hotPathClaim = _mapValue(record, 'hot_path_claim');

  final detourNeeded = _boolValue(toolDetour, 'needed');
  final detourReason = _stringValue(toolDetour, 'reason');
  if (detourNeeded == true && detourReason.trim().isEmpty) {
    diagnostics.add(
      '$label: tool_detour.reason is required when needed is true.',
    );
  }

  if (_stringListValue(
    directProblemPath,
    'declared_surfaces_used_first',
  ).isEmpty) {
    diagnostics.add(
      '$label: direct_problem_path.declared_surfaces_used_first must name at least one declared surface.',
    );
  }

  if (_stringValue(hotPathClaim, 'observed_effect').isEmpty) {
    diagnostics.add(
      '$label: hot_path_claim.observed_effect is required so success is tied to observed behavior, not only a return code.',
    );
  }

  final productImpactLine = _stringValue(outcome, 'product_impact_line');
  if (productImpactLine.isEmpty) {
    diagnostics.add(
      '$label: outcome.product_impact_line is required before claiming success.',
    );
  } else if (!_hasRecognizedProductImpactPrefix(productImpactLine)) {
    diagnostics.add(
      '$label: outcome.product_impact_line must start with one recognized prefix: ${_productImpactLinePrefixes.join(' ')}',
    );
  }

  final attempts = _intValue(toolDetour, 'attempts') ?? 0;
  if (attempts >= 2) {
    if (_boolValue(toolDetour, 'stop_rule_triggered') != true) {
      diagnostics.add(
        '$label: tool_detour.attempts >= 2 requires stop_rule_triggered: true.',
      );
    }
    if (_stringValue(toolDetour, 'return_to_goal_step').trim().isEmpty) {
      diagnostics.add(
        '$label: tool_detour.attempts >= 2 requires a non-empty return_to_goal_step.',
      );
    }
    if (_stringValue(outcome, 'decision') == 'promote') {
      diagnostics.add(
        '$label: outcome.decision must not be promote after a stopped tool detour.',
      );
    }
    if (_boolValue(promotion, 'can_promote_in_this_run') == true) {
      diagnostics.add(
        '$label: promotion.can_promote_in_this_run must be false after a stopped tool detour.',
      );
    }
    final claimedLevel = _stringValue(promotion, 'claimed_level');
    if (claimedLevel.isNotEmpty && claimedLevel != 'none') {
      diagnostics.add(
        '$label: promotion.claimed_level must stay none after a stopped tool detour.',
      );
    }
  }

  final claimedLevel = _stringValue(promotion, 'claimed_level');
  final supportOnly = productImpactLine.toLowerCase().startsWith(
    'support_only:',
  );
  if (supportOnly) {
    if (_stringValue(outcome, 'decision') == 'promote') {
      diagnostics.add(
        '$label: outcome.decision must not be promote when product_impact_line is support_only.',
      );
    }
    if (_boolValue(promotion, 'can_promote_in_this_run') == true) {
      diagnostics.add(
        '$label: promotion.can_promote_in_this_run must be false when product_impact_line is support_only.',
      );
    }
    if (claimedLevel.isNotEmpty && claimedLevel != 'none') {
      diagnostics.add(
        '$label: promotion.claimed_level must stay none when product_impact_line is support_only.',
      );
    }
  }

  if (claimedLevel == 'H5' || claimedLevel == 'S5') {
    final repeatedEvidence = _stringListValue(promotion, 'repeated_evidence');
    if (repeatedEvidence.length < 2) {
      diagnostics.add(
        '$label: promotion.claimed_level $claimedLevel requires at least two repeated_evidence entries.',
      );
    }
    final heldOutBenchmarks = _stringListValue(
      promotion,
      'held_out_benchmarks',
    );
    if (heldOutBenchmarks.isEmpty) {
      diagnostics.add(
        '$label: promotion.claimed_level $claimedLevel requires held_out_benchmarks.',
      );
    }
    if (_stringValue(capability, 'scope') == 'adoption_run') {
      diagnostics.add(
        '$label: promotion.claimed_level $claimedLevel cannot use scope adoption_run.',
      );
    }
  }

  if (_stringValue(capability, 'scope') == 'repo_maturity') {
    final broadEvidence = _stringListValue(promotion, 'broad_evidence');
    if (broadEvidence.isEmpty) {
      diagnostics.add(
        '$label: capability.scope repo_maturity requires promotion.broad_evidence.',
      );
    }
  }
}

bool _hasRecognizedProductImpactPrefix(final String value) {
  final normalized = value.trim().toLowerCase();
  return _productImpactLinePrefixes.any(normalized.startsWith);
}

void _validateRequiredSections(
  final Map<String, dynamic> record,
  final String label,
  final List<String> diagnostics,
) {
  const requiredSections = [
    'run',
    'user_goal',
    'capability',
    'direct_problem_path',
    'tool_detour',
    'generational_architecture_check',
    'outcome',
    'hot_path_claim',
    'promotion',
  ];

  for (final section in requiredSections) {
    if (record[section] is! Map) {
      diagnostics.add(
        '$label: missing required adoption-run section $section.',
      );
    }
  }
}

Map<String, dynamic> _mapValue(
  final Map<String, dynamic> map,
  final String key,
) {
  final value = map[key];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _stringValue(final Map<String, dynamic> map, final String key) =>
    '${map[key] ?? ''}'.trim();

bool? _boolValue(final Map<String, dynamic> map, final String key) {
  final value = map[key];
  return value is bool ? value : null;
}

int? _intValue(final Map<String, dynamic> map, final String key) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

List<String> _stringListValue(
  final Map<String, dynamic> map,
  final String key,
) {
  final value = map[key];
  if (value is! List) return const [];
  return value
      .whereType<Object>()
      .map((final item) => '$item'.trim())
      .where((final item) => item.isNotEmpty)
      .toList(growable: false);
}
