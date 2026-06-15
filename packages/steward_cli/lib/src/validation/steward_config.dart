import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../yaml_utils.dart';

/// Glob-to-RegExp translation utility to avoid external package dependencies.
RegExp globToRegex(final String pattern) {
  var escaped = pattern
      .replaceAll(r'\', r'\\')
      .replaceAll('.', r'\.')
      .replaceAll('+', r'\+')
      .replaceAll(r'$', r'\$')
      .replaceAll('^', r'\^')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)')
      .replaceAll('{', r'\{')
      .replaceAll('}', r'\}')
      .replaceAll('|', r'\|');

  escaped = escaped.replaceAll('**/', 'DOUBLE_STAR_SLASH');
  escaped = escaped.replaceAll('/**', 'SLASH_DOUBLE_STAR');
  escaped = escaped.replaceAll('**', 'DOUBLE_STAR');
  escaped = escaped.replaceAll('*', 'SINGLE_STAR');

  escaped = escaped.replaceAll('DOUBLE_STAR_SLASH', '(?:.*/)?');
  escaped = escaped.replaceAll('SLASH_DOUBLE_STAR', '(?:/.*)?');
  escaped = escaped.replaceAll('DOUBLE_STAR', '.*');
  escaped = escaped.replaceAll('SINGLE_STAR', '[^/]*');

  return RegExp('^$escaped\$');
}

class CustomValidator {
  CustomValidator({
    required this.type,
    required this.files,
    required this.message,
    this.exclude = const [],
    this.substrings = const [],
  });

  final String type;
  final List<String> files;
  final List<String> exclude;
  final List<String> substrings;
  final String message;

  static CustomValidator? fromMap(final Map<String, dynamic> map) {
    final type = map['type'] as String?;
    final filesList = map['files'] as List?;
    final excludeList = map['exclude'] as List?;
    final substringsList = map['substrings'] as List?;
    final message = map['message'] as String?;

    if (type == null || filesList == null || message == null) return null;

    return CustomValidator(
      type: type,
      files: filesList.cast<String>(),
      exclude: excludeList?.cast<String>() ?? const [],
      substrings: substringsList?.cast<String>() ?? const [],
      message: message,
    );
  }

  /// Runs this validator over the workspace root.
  Future<List<String>> validate(final String rootPath) async {
    final errors = <String>[];
    if (type != 'disallowed-substrings') return errors;

    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) return errors;

    final filePatterns = files.map(globToRegex).toList();
    final excludePatterns = exclude.map(globToRegex).toList();

    final List<File> filesToScan = [];
    final ignoreDirNames = {
      '.git',
      '.agents',
      '.steward_temp',
      '.dart_tool',
      'node_modules',
      'build',
      'target',
    };

    await _findFilesRecursive(
      rootDir,
      rootPath,
      filesToScan,
      ignoreDirNames,
      excludePatterns,
    );

    for (final file in filesToScan) {
      final relPath = p
          .relative(file.path, from: rootPath)
          .replaceAll(r'\', '/');

      // Check if file matches file patterns
      final matchesFile = filePatterns.any((final p) => p.hasMatch(relPath));
      if (!matchesFile) continue;

      // Check if file matches exclude patterns
      final matchesExclude = excludePatterns.any(
        (final p) => p.hasMatch(relPath),
      );
      if (matchesExclude) continue;

      // Scan file content
      try {
        final content = await file.readAsString();
        // Fast path: skip file if it doesn't contain any of the substrings
        if (!substrings.any(content.contains)) continue;

        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          for (final sub in substrings) {
            if (lines[i].contains(sub)) {
              errors.add(
                '$relPath:${i + 1} — $message (found forbidden substring: "$sub")',
              );
            }
          }
        }
      } on Object catch (_) {
        // Skip binary or unreadable files gracefully
      }
    }

    return errors;
  }

  Future<void> _findFilesRecursive(
    final Directory dir,
    final String rootPath,
    final List<File> filesList,
    final Set<String> ignoreDirNames,
    final List<RegExp> excludePatterns,
  ) async {
    try {
      final entities = await dir.list(followLinks: false).toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          if (ignoreDirNames.contains(name)) {
            continue;
          }
          final relPath = p
              .relative(entity.path, from: rootPath)
              .replaceAll(r'\', '/');
          final matchesExclude = excludePatterns.any(
            (final p) => p.hasMatch(relPath) || p.hasMatch('$relPath/'),
          );
          if (matchesExclude) {
            continue;
          }
          await _findFilesRecursive(
            entity,
            rootPath,
            filesList,
            ignoreDirNames,
            excludePatterns,
          );
        } else if (entity is File) {
          filesList.add(entity);
        }
      }
    } on Object catch (_) {
      // Ignore directory access errors gracefully
    }
  }
}

class StewardConfig {
  StewardConfig({
    this.schema,
    this.configPath,
    this.archetype,
    this.preferredRunner,
    this.validators = const [],
    this.repo = const {},
    this.harness = const {},
    this.adoption = const {},
    this.stewardship = const {},
    this.actions = const {},
    this.probes = const {},
    this.diagnostics = const {},
    this.unknownCases = const {},
    this.provenance = const {},
    this.harnessName,
    this.harnessDescription,
    this.pipelines = const {},
    this.docs = const {},
    this.governance = const {},
    this.branding = const {},
    this.skillsDistribution = const {},
    this.evals = const {},
    this.telemetry = const {},
  });

  final String? schema;
  final String? configPath;
  final String? archetype;
  final String? preferredRunner;
  final List<CustomValidator> validators;
  final Map<String, dynamic> repo;
  final Map<String, dynamic> harness;
  final Map<String, dynamic> adoption;
  final Map<String, dynamic> stewardship;
  final Map<String, dynamic> actions;
  final Map<String, dynamic> probes;
  final Map<String, dynamic> diagnostics;
  final Map<String, dynamic> unknownCases;
  final Map<String, dynamic> provenance;
  final String? harnessName;
  final String? harnessDescription;
  final Map<String, dynamic> pipelines;
  final Map<String, String> docs;
  final Map<String, dynamic> governance;
  final Map<String, dynamic> branding;
  final Map<String, dynamic> skillsDistribution;
  final Map<String, dynamic> evals;
  final Map<String, dynamic> telemetry;

  bool get isV1 => schema == 'steward/v1';

  List<StewardAction> get typedActions => actions.entries
      .where((final entry) => entry.value is Map)
      .map(
        (final entry) => StewardAction.fromMap(
          entry.key,
          Map<String, dynamic>.from(entry.value as Map),
        ),
      )
      .toList();

  static Future<StewardConfig> load(final String rootPath) async {
    final result = await loadChecked(rootPath);
    return result.config;
  }

  static Future<StewardConfigLoadResult> loadChecked(
    final String rootPath,
  ) async {
    var file = File(p.join(rootPath, 'steward.yaml'));
    if (!file.existsSync()) {
      file = File(p.join(rootPath, 'steward.yml'));
      if (!file.existsSync()) {
        return StewardConfigLoadResult(
          config: StewardConfig(),
          diagnostics: const [
            ConfigDiagnostic.error(
              path: 'steward.yaml',
              message: 'Missing steward.yaml or steward.yml.',
            ),
          ],
        );
      }
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      final data = yamlToDart(yaml);

      if (data is! Map) {
        return StewardConfigLoadResult(
          config: StewardConfig(configPath: file.path),
          diagnostics: const [
            ConfigDiagnostic.error(
              path: 'steward.yaml',
              message: 'steward.yaml must contain a YAML mapping.',
            ),
          ],
        );
      }

      final rootMap = Map<String, dynamic>.from(data);
      final schema = rootMap['schema'] as String?;
      final repoMap = _stringMap(rootMap['repo']);
      final harnessMap = _stringMap(rootMap['harness']);
      final adoptionMap = _stringMap(rootMap['adoption']);
      final stewardshipMap = _stringMap(rootMap['stewardship']);
      final actionsMap = _stringMap(rootMap['actions']);
      final probesMap = _stringMap(rootMap['probes']);
      final diagnosticsMap = _stringMap(rootMap['diagnostics']);
      final unknownCasesMap = _stringMap(rootMap['unknown_cases']);
      final provenanceMap = _stringMap(rootMap['provenance']);

      final archetype =
          rootMap['archetype'] as String? ?? repoMap?['archetype'] as String?;
      final preferredRunner = rootMap['preferredRunner'] as String?;
      final validatorsJson = rootMap['validators'] as List?;

      final validators = <CustomValidator>[];
      if (validatorsJson != null) {
        for (final item in validatorsJson) {
          if (item is Map) {
            final v = CustomValidator.fromMap(Map<String, dynamic>.from(item));
            if (v != null) {
              validators.add(v);
            }
          }
        }
      }

      final harnessName = harnessMap?['name'] as String?;
      final harnessDescription = harnessMap?['description'] as String?;
      final pipelinesMap = _stringMap(rootMap['pipelines']);
      final docsMap = _stringMap(rootMap['docs']);
      final docs = <String, String>{};
      docsMap?.forEach((final key, final value) => docs[key] = '$value');

      final governanceMap = _stringMap(rootMap['governance']) ?? const {};
      final brandingMap = _stringMap(rootMap['branding']) ?? const {};
      final skillsDistributionMap =
          _stringMap(rootMap['skills_distribution']) ?? const {};

      final bannedWords = brandingMap['banned_words'] as List?;
      if (bannedWords != null && bannedWords.isNotEmpty) {
        validators.add(
          CustomValidator(
            type: 'disallowed-substrings',
            files: ['**/*.md', '**/*.mdx'],
            exclude:
                (brandingMap['ignored_paths'] as List?)?.cast<String>() ??
                const [],
            substrings: bannedWords.map((final e) => e.toString()).toList(),
            message: 'Brand identity violation (banned jargon)',
          ),
        );
      }

      final config = StewardConfig(
        schema: schema,
        configPath: file.path,
        archetype: archetype,
        preferredRunner: preferredRunner,
        validators: validators,
        repo: repoMap ?? const {},
        harness: harnessMap ?? const {},
        adoption: adoptionMap ?? const {},
        stewardship: stewardshipMap ?? const {},
        actions: actionsMap ?? const {},
        probes: probesMap ?? const {},
        diagnostics: diagnosticsMap ?? const {},
        unknownCases: unknownCasesMap ?? const {},
        provenance: provenanceMap ?? const {},
        harnessName: harnessName,
        harnessDescription: harnessDescription,
        pipelines: pipelinesMap ?? const {},
        docs: docs,
        governance: Map<String, dynamic>.from(governanceMap),
        branding: Map<String, dynamic>.from(brandingMap),
        skillsDistribution: Map<String, dynamic>.from(skillsDistributionMap),
        evals: _stringMap(rootMap['evals']) ?? const {},
        telemetry: _stringMap(rootMap['telemetry']) ?? const {},
      );

      return StewardConfigLoadResult(
        config: config,
        diagnostics: _validateContract(config, rootPath),
      );
    } on Object catch (_) {
      return StewardConfigLoadResult(
        config: StewardConfig(configPath: file.path),
        diagnostics: const [
          ConfigDiagnostic.error(
            path: 'steward.yaml',
            message: 'Could not parse steward.yaml.',
          ),
        ],
      );
    }
  }
}

class StewardConfigLoadResult {
  const StewardConfigLoadResult({
    required this.config,
    this.diagnostics = const [],
  });

  final StewardConfig config;
  final List<ConfigDiagnostic> diagnostics;

  bool get ok => diagnostics.every((final diagnostic) => !diagnostic.isError);
}

class ConfigDiagnostic {
  const ConfigDiagnostic({
    required this.severity,
    required this.path,
    required this.message,
  });

  const ConfigDiagnostic.error({required this.path, required this.message})
    : severity = 'error';

  const ConfigDiagnostic.warning({required this.path, required this.message})
    : severity = 'warning';

  final String severity;
  final String path;
  final String message;

  bool get isError => severity == 'error';

  Map<String, dynamic> toJson() => {
    'severity': severity,
    'path': path,
    'message': message,
  };
}

class StewardAction {
  const StewardAction({
    required this.id,
    required this.raw,
    required this.kind,
    required this.desc,
    required this.command,
    required this.effects,
    required this.safety,
    required this.limits,
    required this.outputs,
    required this.evidence,
  });

  factory StewardAction.fromMap(
    final String id,
    final Map<String, dynamic> raw,
  ) => StewardAction(
    id: id,
    raw: raw,
    kind: raw['kind'] as String? ?? '',
    desc: raw['desc'] as String? ?? '',
    command: _stringMap(raw['command']) ?? const {},
    effects: _stringMap(raw['effects']) ?? const {},
    safety: _stringMap(raw['safety']) ?? const {},
    limits: _stringMap(raw['limits']) ?? const {},
    outputs: raw['outputs'] is List
        ? List<dynamic>.from(raw['outputs'] as List)
        : const [],
    evidence: _stringMap(raw['evidence']) ?? const {},
  );

  final String id;
  final Map<String, dynamic> raw;
  final String kind;
  final String desc;
  final Map<String, dynamic> command;
  final Map<String, dynamic> effects;
  final Map<String, dynamic> safety;
  final Map<String, dynamic> limits;
  final List<dynamic> outputs;
  final Map<String, dynamic> evidence;

  String get safetyClass => safety['class'] as String? ?? '';
  String get defaultPolicy => safety['default_policy'] as String? ?? '';
  bool get requiresConfirmation => safety['requires_confirmation'] == true;

  bool get isAutoEligible =>
      defaultPolicy == 'auto' &&
      !requiresConfirmation &&
      safetyClass != 'repo_mutation' &&
      safetyClass != 'external' &&
      safetyClass != 'destructive' &&
      !_truthyEffect(effects['network']) &&
      !_truthyEffect(effects['secrets']) &&
      !_truthyEffect(effects['destructive']) &&
      !_mutationEffect(effects['git']);

  List<String> quickPolicyViolations() {
    final violations = <String>[];
    if (defaultPolicy != 'auto') {
      violations.add('safety.default_policy is not auto');
    }
    if (requiresConfirmation) {
      violations.add('safety.requires_confirmation is true');
    }
    if (safetyClass == 'repo_mutation' ||
        safetyClass == 'external' ||
        safetyClass == 'destructive') {
      violations.add('safety.class $safetyClass is not allowed in quick');
    }
    if (command['shell'] == true) {
      violations.add('command.shell is true');
    }
    if (_truthyEffect(effects['network'])) {
      violations.add('effects.network is true');
    }
    if (_truthyEffect(effects['secrets'])) {
      violations.add('effects.secrets is true');
    }
    if (_truthyEffect(effects['destructive'])) {
      violations.add('effects.destructive is true');
    }
    if (_mutationEffect(effects['git'])) {
      violations.add('effects.git mutates repository state');
    }
    if (_nonEmptyEffect(effects['fs_write'])) {
      violations.add('effects.fs_write is non-empty');
    }
    final timeoutMs = limits['timeout_ms'];
    if (timeoutMs is int && timeoutMs > 10000) {
      violations.add('limits.timeout_ms exceeds quick budget');
    }
    return violations;
  }

  bool get isQuickEligible => quickPolicyViolations().isEmpty;

  Map<String, dynamic> summaryJson() => {
    'id': id,
    'kind': kind,
    'desc': desc,
    'safety': {
      'class': safetyClass,
      'default_policy': defaultPolicy,
      'requires_confirmation': requiresConfirmation,
    },
    'effects': effects,
    'auto_eligible': isAutoEligible,
    'quick_eligible': isQuickEligible,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    ...raw,
    'auto_eligible': isAutoEligible,
    'quick_eligible': isQuickEligible,
  };
}

List<ConfigDiagnostic> _validateContract(
  final StewardConfig config,
  final String rootPath,
) {
  final diagnostics = <ConfigDiagnostic>[];

  if (!config.isV1) {
    return diagnostics;
  }

  void requireMap(final String key, final Map<String, dynamic> value) {
    if (value.isEmpty) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: key,
          message: 'schema: steward/v1 requires a non-empty $key map.',
        ),
      );
    }
  }

  requireMap('repo', config.repo);
  requireMap('harness', config.harness);
  requireMap('adoption', config.adoption);
  requireMap('stewardship', config.stewardship);
  requireMap('diagnostics', config.diagnostics);
  requireMap('unknown_cases', config.unknownCases);
  requireMap('provenance', config.provenance);
  _validateStewardshipPillars(config.stewardship, diagnostics);
  final harnessPillar = _stringMap(config.stewardship['harness']);
  final harnessEnabled = harnessPillar?['enabled'] == true;
  if (harnessEnabled) {
    requireMap('actions', config.actions);
    requireMap('probes', config.probes);
  }

  _requireString(config.repo, 'repo', 'id', diagnostics);
  _requireString(config.repo, 'repo', 'archetype', diagnostics);
  final archetype = config.repo['archetype'];
  const allowedArchetypes = {
    'app',
    'library',
    'cli_tool',
    'plugin',
    'harness',
    'meta_governance',
  };
  if (archetype is String && !allowedArchetypes.contains(archetype)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: 'repo.archetype',
        message:
            'repo.archetype must be one of: ${allowedArchetypes.join(", ")}.',
      ),
    );
  }
  _requireString(config.harness, 'harness', 'name', diagnostics);
  _requireString(config.harness, 'harness', 'mode', diagnostics);
  _requireString(config.adoption, 'adoption', 'status', diagnostics);
  _requireString(config.adoption, 'adoption', 'owner', diagnostics);
  _requireMap(config.adoption, 'adoption', 'gate', diagnostics);
  final entrypoints = _stringMap(config.harness['entrypoints']);
  if (entrypoints == null || entrypoints.isEmpty) {
    diagnostics.add(
      const ConfigDiagnostic.error(
        path: 'harness.entrypoints',
        message: 'harness.entrypoints must contain at least one entrypoint.',
      ),
    );
  } else {
    for (final entry in entrypoints.entries) {
      if (entry.value is! String || (entry.value as String).trim().isEmpty) {
        diagnostics.add(
          ConfigDiagnostic.error(
            path: 'harness.entrypoints.${entry.key}',
            message: 'Harness entrypoint values must be non-empty strings.',
          ),
        );
      }
    }
  }

  _validateLegacyPipelines(config, diagnostics);
  _validateActions(config, diagnostics);
  _validateProbes(config, diagnostics);
  _requireString(config.unknownCases, 'unknown_cases', 'path', diagnostics);
  _requireString(
    config.unknownCases,
    'unknown_cases',
    'retention',
    diagnostics,
  );

  for (final key in ['dependencies', 'artifacts', 'benchmarks']) {
    if (config.provenance[key] is! List) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'provenance.$key',
          message: 'provenance.$key must be a list.',
        ),
      );
    }
  }
  _validateBenchmarkManifests(config, rootPath, diagnostics);

  return diagnostics;
}

void _validateStewardshipPillars(
  final Map<String, dynamic> stewardship,
  final List<ConfigDiagnostic> diagnostics,
) {
  const requiredPillars = {
    'governance',
    'knowledge',
    'repo_quality',
    'skill_lifecycle',
    'quality',
    'harness',
    'release',
    'review_handoff',
    'strategic_alignment',
    'security',
    'org',
  };

  for (final pillar in requiredPillars) {
    final value = stewardship[pillar];
    if (value is! Map || value.isEmpty) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'stewardship.$pillar',
          message:
              'schema: steward/v1 requires stewardship.$pillar pillar proof.',
        ),
      );
    }
  }
}

void _validateLegacyPipelines(
  final StewardConfig config,
  final List<ConfigDiagnostic> diagnostics,
) {
  for (final entry in config.pipelines.entries) {
    if (entry.value is String) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'pipelines.${entry.key}',
          message:
              'schema: steward/v1 forbids raw string pipelines; declare actions instead.',
        ),
      );
    } else if (entry.value is Map && (entry.value as Map).containsKey('cmd')) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'pipelines.${entry.key}.cmd',
          message:
              'schema: steward/v1 forbids legacy pipelines.*.cmd; declare actions.*.command.argv instead.',
        ),
      );
    }
  }
}

void _validateActions(
  final StewardConfig config,
  final List<ConfigDiagnostic> diagnostics,
) {
  final idPattern = RegExp(r'^[a-z][a-z0-9._-]*$');
  const allowedSafetyClasses = {
    'observe',
    'bounded_local',
    'repo_mutation',
    'external',
    'destructive',
  };

  for (final entry in config.actions.entries) {
    final id = entry.key;
    final value = entry.value;
    if (!idPattern.hasMatch(id)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id',
          message:
              r'Action ids must match ^[a-z][a-z0-9._-]*$ for stable agent references.',
        ),
      );
    }
    if (value is! Map) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id',
          message: 'Action definitions must be maps.',
        ),
      );
      continue;
    }

    final action = StewardAction.fromMap(id, Map<String, dynamic>.from(value));
    if (action.kind != 'command') {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.kind',
          message: 'Slice 0 supports only kind: command.',
        ),
      );
    }
    _requireString(action.raw, 'actions.$id', 'desc', diagnostics);
    _requireString(action.raw, 'actions.$id', 'cwd', diagnostics);
    _requireMap(action.raw, 'actions.$id', 'command', diagnostics);
    _requireMap(action.raw, 'actions.$id', 'effects', diagnostics);
    _requireMap(action.raw, 'actions.$id', 'safety', diagnostics);
    _requireMap(action.raw, 'actions.$id', 'limits', diagnostics);
    _requireList(action.raw, 'actions.$id', 'outputs', diagnostics);
    _requireMap(action.raw, 'actions.$id', 'evidence', diagnostics);

    final argv = action.command['argv'];
    if (argv is! List ||
        argv.isEmpty ||
        argv.any((final item) => item is! String)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.command.argv',
          message: 'command.argv must be a non-empty list of strings.',
        ),
      );
    }
    if (action.command['shell'] is! bool) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.command.shell',
          message: 'command.shell must be a boolean.',
        ),
      );
    }
    if (!allowedSafetyClasses.contains(action.safetyClass)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.safety.class',
          message:
              'safety.class must be one of ${allowedSafetyClasses.join(", ")}.',
        ),
      );
    }
    _requireString(
      action.safety,
      'actions.$id.safety',
      'default_policy',
      diagnostics,
    );
    if (action.safety['requires_confirmation'] is! bool) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.safety.requires_confirmation',
          message: 'safety.requires_confirmation must be a boolean.',
        ),
      );
    }
    if (action.limits['timeout_ms'] is! int) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.limits.timeout_ms',
          message: 'limits.timeout_ms must be an integer.',
        ),
      );
    }
    if (action.limits['max_output_bytes'] is! int) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'actions.$id.limits.max_output_bytes',
          message: 'limits.max_output_bytes must be an integer.',
        ),
      );
    }
    _validateActionEffects(action, diagnostics);
    _validateActionOutputs(action, diagnostics);
  }
}

void _validateActionEffects(
  final StewardAction action,
  final List<ConfigDiagnostic> diagnostics,
) {
  final id = action.id;
  if (action.effects.containsKey('filesystem')) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: 'actions.$id.effects.filesystem',
        message:
            'schema: steward/v1 forbids effects.filesystem; use explicit fs_read and fs_write lists.',
      ),
    );
  }
  _requireStringList(
    action.effects,
    'actions.$id.effects',
    'fs_read',
    diagnostics,
  );
  _requireStringList(
    action.effects,
    'actions.$id.effects',
    'fs_write',
    diagnostics,
  );
}

void _validateActionOutputs(
  final StewardAction action,
  final List<ConfigDiagnostic> diagnostics,
) {
  final id = action.id;
  final outputs = action.raw['outputs'];
  if (outputs is! List) {
    return;
  }
  if (outputs.isEmpty) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: 'actions.$id.outputs',
        message: 'outputs must contain at least one output record.',
      ),
    );
    return;
  }

  for (var index = 0; index < outputs.length; index++) {
    final output = outputs[index];
    final path = 'actions.$id.outputs.$index';
    if (output is! Map) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: path,
          message: 'Output records must be maps.',
        ),
      );
      continue;
    }
    final outputMap = Map<String, dynamic>.from(output);
    for (final key in ['id', 'kind', 'retention']) {
      _requireString(outputMap, path, key, diagnostics);
    }
    if (outputMap['required'] is! bool) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: '$path.required',
          message: 'Output required must be a boolean.',
        ),
      );
    }
    final outputPath = outputMap['path'];
    if (outputPath is String && !_isSafeRelativePath(outputPath)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: '$path.path',
          message: 'Output paths must be relative paths inside the repository.',
        ),
      );
    }
  }
}

void _validateProbes(
  final StewardConfig config,
  final List<ConfigDiagnostic> diagnostics,
) {
  for (final entry in config.probes.entries) {
    final id = entry.key;
    final value = entry.value;
    if (value is! Map) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'probes.$id',
          message: 'Probe definitions must be maps.',
        ),
      );
      continue;
    }
    final probe = Map<String, dynamic>.from(value);
    _requireString(probe, 'probes.$id', 'profile', diagnostics);
    final actions = probe['actions'];
    if (actions is! List ||
        actions.any((final actionId) => actionId is! String)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: 'probes.$id.actions',
          message: 'Probe actions must be a list of action ids.',
        ),
      );
      continue;
    }
    for (final actionId in actions.cast<String>()) {
      if (!config.actions.containsKey(actionId)) {
        diagnostics.add(
          ConfigDiagnostic.error(
            path: 'probes.$id.actions',
            message: 'Probe references unknown action "$actionId".',
          ),
        );
        continue;
      }
      final actionValue = config.actions[actionId];
      if (probe['profile'] == 'quick' && actionValue is Map) {
        final action = StewardAction.fromMap(
          actionId,
          Map<String, dynamic>.from(actionValue),
        );
        final violations = action.quickPolicyViolations();
        if (violations.isNotEmpty) {
          diagnostics.add(
            ConfigDiagnostic.error(
              path: 'probes.$id.actions',
              message:
                  'Quick probe action "$actionId" violates policy: ${violations.join("; ")}.',
            ),
          );
        }
      }
    }
  }
}

void _validateBenchmarkManifests(
  final StewardConfig config,
  final String rootPath,
  final List<ConfigDiagnostic> diagnostics,
) {
  final benchmarks = config.provenance['benchmarks'];
  if (benchmarks is! List) {
    return;
  }

  for (var index = 0; index < benchmarks.length; index++) {
    final entry = benchmarks[index];
    final path = 'provenance.benchmarks.$index';
    if (entry is! Map) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: path,
          message: 'Benchmark entries must be maps.',
        ),
      );
      continue;
    }

    final benchmark = Map<String, dynamic>.from(entry);
    final manifestPath = benchmark['manifest'];
    if (manifestPath is String && manifestPath.trim().isNotEmpty) {
      if (!_isSafeRelativePath(manifestPath)) {
        diagnostics.add(
          ConfigDiagnostic.error(
            path: '$path.manifest',
            message:
                'Benchmark manifest paths must be relative paths inside the repository.',
          ),
        );
        continue;
      }
      final manifestFile = File(p.join(rootPath, manifestPath));
      if (!manifestFile.existsSync()) {
        diagnostics.add(
          ConfigDiagnostic.error(
            path: '$path.manifest',
            message: 'Benchmark manifest does not exist: $manifestPath.',
          ),
        );
        continue;
      }
      try {
        final parsed = yamlToDart(loadYaml(manifestFile.readAsStringSync()));
        if (parsed is! Map) {
          diagnostics.add(
            ConfigDiagnostic.error(
              path: '$path.manifest',
              message: 'Benchmark manifest must contain a YAML map.',
            ),
          );
          continue;
        }
        final manifest = Map<String, dynamic>.from(parsed);
        final declaredId = benchmark['id'] as String?;
        if (declaredId != null &&
            manifest['scenario'] is String &&
            declaredId != manifest['scenario']) {
          diagnostics.add(
            ConfigDiagnostic.error(
              path: '$path.id',
              message:
                  'Benchmark id "$declaredId" must match scenario "${manifest['scenario']}".',
            ),
          );
        }
        _validateScenarioManifest(
          manifest,
          path,
          config,
          diagnostics,
          manifestPath: manifestPath,
        );
      } on Object catch (_) {
        diagnostics.add(
          ConfigDiagnostic.error(
            path: '$path.manifest',
            message: 'Could not parse benchmark manifest: $manifestPath.',
          ),
        );
      }
      continue;
    }

    _validateScenarioManifest(benchmark, path, config, diagnostics);
  }
}

void _validateScenarioManifest(
  final Map<String, dynamic> scenario,
  final String path,
  final StewardConfig config,
  final List<ConfigDiagnostic> diagnostics, {
  final String? manifestPath,
}) {
  if (scenario['schema'] != 'steward/scenario-manifest/v1') {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.schema',
        message: 'Scenario schema must be steward/scenario-manifest/v1.',
      ),
    );
  }
  for (final key in [
    'repo',
    'scenario',
    'status',
    'safe_first_probe',
    'owner',
  ]) {
    _requireString(scenario, path, key, diagnostics);
  }

  final status = scenario['status'];
  if (status is String &&
      !const {'runnable', 'blocked', 'planned'}.contains(status)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.status',
        message: 'Scenario status must be runnable, blocked, or planned.',
      ),
    );
  }
  if (status == 'blocked' && '${scenario['blocked_by'] ?? ''}'.trim().isEmpty) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.blocked_by',
        message: 'Blocked scenarios must declare blocked_by.',
      ),
    );
  }

  final safeFirstProbe = scenario['safe_first_probe'];
  if (safeFirstProbe is String && !config.actions.containsKey(safeFirstProbe)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.safe_first_probe',
        message:
            'safe_first_probe references unknown action "$safeFirstProbe".',
      ),
    );
  }

  _validateScenarioSource(scenario['source'], path, diagnostics);
  _validateScenarioActions(
    scenario['required_actions'],
    path,
    config,
    diagnostics,
  );
  _validateScenarioArtifacts(scenario['artifacts'], path, diagnostics);

  if (manifestPath != null &&
      scenario['source'] is Map &&
      (scenario['source'] as Map)['steward_contract'] == manifestPath) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.source.steward_contract',
        message:
            'source.steward_contract must point to steward.yaml, not the scenario manifest itself.',
      ),
    );
  }
}

void _validateScenarioSource(
  final Object? source,
  final String path,
  final List<ConfigDiagnostic> diagnostics,
) {
  if (source is! Map) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.source',
        message:
            'Scenario source must declare git, commit, and steward_contract.',
      ),
    );
    return;
  }
  final sourceMap = Map<String, dynamic>.from(source);
  _requireString(sourceMap, '$path.source', 'git', diagnostics);
  _requireString(sourceMap, '$path.source', 'commit', diagnostics);
  _requireString(sourceMap, '$path.source', 'steward_contract', diagnostics);

  final git = sourceMap['git'];
  if (git is String && !_isDurableGitSource(git)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.source.git',
        message:
            'source.git must be a durable git URL, not a local filesystem path.',
      ),
    );
  }
  final commit = sourceMap['commit'];
  if (commit is String && !RegExp(r'^[a-f0-9]{40}$').hasMatch(commit)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.source.commit',
        message:
            'source.commit must be a resolved 40-character lowercase git SHA.',
      ),
    );
  }
  final contract = sourceMap['steward_contract'];
  if (contract is String && !_isSafeRelativePath(contract)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.source.steward_contract',
        message:
            'source.steward_contract must be a relative path inside the repository.',
      ),
    );
  }
}

void _validateScenarioActions(
  final Object? requiredActions,
  final String path,
  final StewardConfig config,
  final List<ConfigDiagnostic> diagnostics,
) {
  if (requiredActions is! List || requiredActions.isEmpty) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.required_actions',
        message: 'required_actions must be a non-empty list of action ids.',
      ),
    );
    return;
  }
  for (final actionId in requiredActions) {
    if (actionId is! String || actionId.trim().isEmpty) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: '$path.required_actions',
          message: 'required_actions must contain only non-empty strings.',
        ),
      );
      continue;
    }
    if (!config.actions.containsKey(actionId)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: '$path.required_actions',
          message: 'required_actions references unknown action "$actionId".',
        ),
      );
    }
  }
}

void _validateScenarioArtifacts(
  final Object? artifacts,
  final String path,
  final List<ConfigDiagnostic> diagnostics,
) {
  if (artifacts is! List || artifacts.isEmpty) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.artifacts',
        message: 'artifacts must be a non-empty list.',
      ),
    );
    return;
  }

  for (var index = 0; index < artifacts.length; index++) {
    final artifact = artifacts[index];
    final artifactPath = '$path.artifacts.$index';
    if (artifact is! Map) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: artifactPath,
          message: 'Artifact entries must be maps.',
        ),
      );
      continue;
    }
    final artifactMap = Map<String, dynamic>.from(artifact);
    for (final key in ['id', 'kind', 'path']) {
      _requireString(artifactMap, artifactPath, key, diagnostics);
    }
    if (artifactMap['required'] is! bool) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: '$artifactPath.required',
          message: 'Artifact required must be a boolean.',
        ),
      );
    }
    final pathValue = artifactMap['path'];
    if (pathValue is String && !_isSafeRelativePath(pathValue)) {
      diagnostics.add(
        ConfigDiagnostic.error(
          path: '$artifactPath.path',
          message:
              'Artifact paths must be relative paths inside the repository.',
        ),
      );
    }
  }
}

void _requireString(
  final Map<String, dynamic> map,
  final String path,
  final String key,
  final List<ConfigDiagnostic> diagnostics,
) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.$key',
        message: '$path.$key must be a non-empty string.',
      ),
    );
  }
}

void _requireMap(
  final Map<String, dynamic> map,
  final String path,
  final String key,
  final List<ConfigDiagnostic> diagnostics,
) {
  if (map[key] is! Map) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.$key',
        message: '$path.$key must be a map.',
      ),
    );
  }
}

void _requireList(
  final Map<String, dynamic> map,
  final String path,
  final String key,
  final List<ConfigDiagnostic> diagnostics,
) {
  if (map[key] is! List) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.$key',
        message: '$path.$key must be a list.',
      ),
    );
  }
}

void _requireStringList(
  final Map<String, dynamic> map,
  final String path,
  final String key,
  final List<ConfigDiagnostic> diagnostics,
) {
  final value = map[key];
  if (value is! List || value.any((final item) => item is! String)) {
    diagnostics.add(
      ConfigDiagnostic.error(
        path: '$path.$key',
        message: '$path.$key must be a list of strings.',
      ),
    );
  }
}

Map<String, dynamic>? _stringMap(final Object? value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

bool _truthyEffect(final Object? value) => value == true;

bool _mutationEffect(final Object? value) {
  if (value == true) return true;
  if (value is String) {
    final lowered = value.toLowerCase();
    return lowered == 'write' ||
        lowered == 'mutation' ||
        lowered == 'mutate' ||
        lowered == 'repo_mutation' ||
        lowered == 'destructive';
  }
  if (value is List) {
    return value.any(_mutationEffect);
  }
  return false;
}

bool _nonEmptyEffect(final Object? value) {
  if (value is List) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  if (value is String) return value.trim().isNotEmpty;
  return value == true;
}

bool _isSafeRelativePath(final String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (p.isAbsolute(trimmed)) return false;
  final parts = p.split(p.normalize(trimmed));
  return !parts.contains('..') && (parts.isEmpty || parts.first != '~');
}

bool _isDurableGitSource(final String value) {
  final trimmed = value.trim();
  return trimmed.startsWith('https://') ||
      trimmed.startsWith('http://') ||
      trimmed.startsWith('ssh://') ||
      RegExp(r'^[^@\s]+@[^:\s]+:[^\s]+$').hasMatch(trimmed);
}
