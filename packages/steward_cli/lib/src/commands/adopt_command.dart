import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Initializes Skill Steward inside a project workspace.
class AdoptCommand extends Command<void> {
  AdoptCommand() {
    argParser
      ..addOption(
        'archetype',
        allowed: const [
          'app',
          'library',
          'cli_tool',
          'plugin',
          'harness',
          'meta_governance',
        ],
        help: 'Set the primary repository archetype explicitly.',
      )
      ..addFlag(
        'with-harness',
        negatable: false,
        help:
            'Also scaffold a quick-safe action, probe, and benchmark scenario for harness proof.',
      );
  }

  @override
  final name = 'adopt';

  @override
  final description =
      'Initialize Skill Steward configuration and agent map in the project.';

  @override
  Future<void> run() async {
    final currentDir = Directory.current.absolute.path;
    final withHarness = argResults?['with-harness'] == true;
    final requestedArchetype = argResults?['archetype'] as String?;

    // 1. Setup skills.json
    final skillsJsonFile = File(p.join(currentDir, 'skills.json'));
    if (skillsJsonFile.existsSync()) {
      stdout.writeln('✓ skills.json already exists in project root.');
    } else {
      final initialConfig = {
        r'$schema': 'https://unpkg.com/skillman/skills_schema.json',
        'skills': [],
      };
      await skillsJsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(initialConfig),
      );
      stdout.writeln('Created skills.json in project root.');
    }

    // 2. Setup steward.yaml
    final stewardYamlFile = File(p.join(currentDir, 'steward.yaml'));
    final stewardYmlFile = File(p.join(currentDir, 'steward.yml'));
    if (stewardYamlFile.existsSync() || stewardYmlFile.existsSync()) {
      stdout.writeln('✓ steward.yaml already exists in project root.');
    } else {
      final archetypeDetection = requestedArchetype == null
          ? _detectArchetype(currentDir)
          : _ArchetypeDetection(
              archetype: requestedArchetype,
              confidence: 1,
              signals: ['explicit --archetype'],
            );
      final nativeValidation = _detectNativeValidation(currentDir);
      final ownsInstallableSkills = _ownsInstallableSkills(currentDir);

      final repoId = p
          .basename(currentDir)
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9_-]+'), '_')
          .replaceAll(RegExp('_+'), '_');
      final gitSource = withHarness ? await _gitSourceFacts(currentDir) : null;
      final template = withHarness
          ? _harnessTemplate(
              repoId: repoId,
              archetypeDetection: archetypeDetection,
              nativeValidation: nativeValidation,
              ownsInstallableSkills: ownsInstallableSkills,
              includeBenchmark: gitSource != null,
            )
          : _baselineTemplate(
              repoId: repoId,
              archetypeDetection: archetypeDetection,
              nativeValidation: nativeValidation,
              ownsInstallableSkills: ownsInstallableSkills,
            );
      await stewardYamlFile.writeAsString(template);
      stdout.writeln('Created steward.yaml in project root.');

      if (withHarness && gitSource != null) {
        final scenarioDir = Directory(
          p.join(currentDir, 'steward', 'scenarios'),
        )..createSync(recursive: true);
        final scenarioFile = File(
          p.join(scenarioDir.path, '$repoId-contract-status-smoke.yaml'),
        );
        await scenarioFile.writeAsString(
          _scenarioTemplate(repoId: repoId, gitSource: gitSource),
        );
        stdout.writeln(
          'Created steward/scenarios/$repoId-contract-status-smoke.yaml.',
        );
      } else if (withHarness) {
        stdout.writeln(
          'Skipped benchmark scenario: durable git remote and HEAD commit were not available.',
        );
      }
    }

    // 3. Scan for task runner configs
    final detectedConfigs = <String>[];
    for (final filename in [
      'Justfile',
      'justfile',
      'Makefile',
      'makefile',
      'package.json',
      'pubspec.yaml',
      'Cargo.toml',
      'pyproject.toml',
    ]) {
      if (File(p.join(currentDir, filename)).existsSync()) {
        detectedConfigs.add(filename);
      }
    }
    if (detectedConfigs.isNotEmpty) {
      stdout.writeln(
        'Detected workspace configurations: ${detectedConfigs.join(", ")}',
      );
    } else {
      stdout.writeln(
        'No standard task runner config detected. Consider creating a Justfile.',
      );
    }

    // 4. Create AGENTS.md
    final agentsMdFile = File(p.join(currentDir, 'AGENTS.md'));
    if (agentsMdFile.existsSync()) {
      stdout.writeln('✓ AGENTS.md already exists in project root.');
    } else {
      const agentsMdContent = '''
# AGENTS.md — Agent Entrypoint Map

Welcome. This project uses **Skill Steward** to make repository purpose, validation, docs, and agent handoff legible.

## Operational Desk

Run the following commands to interact with the project's agentic tools:

- **Show operational map**: `steward map`
- **Inspect Steward contract**: `steward doctor --json`
- **Validate workspace**: use the native validation command recorded in `steward.yaml`

## Claims and Evidence

Before claiming readiness, maturity, harness support, steward status, or adoption:

1. Name the exact claim.
2. Check the weakest proof that supports only that claim.
3. Route the durable artifact:
   - ADR for durable decisions and trade-offs.
   - FAQ/docs for standing why/how guidance.
   - Check/tool/test for repeated deterministic drift.
   - Current ledger for the weakest true current status.
   - Evidence for real proof or blocked proof.
   - Delete completed plans after extracting durable truth.
4. Record non-claims.

If this repo needs a current claim ledger, run `steward evidence init --minimal`.
Use `steward.yaml` and harness proof only when typed actions, probes, or benchmarks help real repo work.

## Active Skills

Skills are installed locally under `.agents/skills/`. You can view them using:
- `steward list`

For more information on the project charter and decisions:
- Read [NORTH_STAR.mdx](docs/NORTH_STAR.mdx) (if present)
- Read [ADR Index](docs/decisions/README) (if present)
''';
      await agentsMdFile.writeAsString(agentsMdContent);
      stdout.writeln('Created AGENTS.md in project root.');
    }

    stdout.writeln(
      '\nSkill Steward adoption complete. Try running "steward map" next.',
    );
  }
}

String _baselineTemplate({
  required final String repoId,
  required final _ArchetypeDetection archetypeDetection,
  required final String nativeValidation,
  required final bool ownsInstallableSkills,
}) =>
    '''
schema: steward/v1
repo:
  id: $repoId
  archetype: ${archetypeDetection.archetype}
  archetype_detection:
    confidence: ${archetypeDetection.confidence}
    signals:${_yamlList(archetypeDetection.signals)}

harness:
  name: steward
  mode: cli
  entrypoints:
    cli: steward

adoption:
  status: adopting
  owner: $repoId
  gate:
    pillar: quality

stewardship:
  governance:
    charter: AGENTS.md
    adr_dir: docs/decisions
  knowledge:
    docs_map: AGENTS.md
    source_policy: required_for_external_claims
  repo_quality:
    contract_spec: steward.yaml
    maturity_model: general_stewardship
  skill_lifecycle:
    installable_skills: $ownsInstallableSkills
    registry: skills.json
  quality:
    validate: $nativeValidation
    evidence: .steward/evidence
  harness:
    enabled: false
    action_contract: deferred
  release:
    changelog: CHANGELOG.md
    artifact_provenance: required
  review_handoff:
    moe_required_for_architecture: true
  strategic_alignment:
    vision_source: AGENTS.md
    success_evidence: required
  security:
    action_effects: required
    redaction: steward/redaction/v1
  org:
    owners: AGENTS.md

actions: {}

probes: {}

diagnostics:
  cases: {}

unknown_cases:
  path: .steward/unknown-cases/
  retention: local

provenance:
  dependencies: []
  artifacts: []
  benchmarks: []
'''
        .trimLeft();

String _harnessTemplate({
  required final String repoId,
  required final _ArchetypeDetection archetypeDetection,
  required final String nativeValidation,
  required final bool ownsInstallableSkills,
  required final bool includeBenchmark,
}) =>
    '''
schema: steward/v1
repo:
  id: $repoId
  archetype: ${archetypeDetection.archetype}
  archetype_detection:
    confidence: ${archetypeDetection.confidence}
    signals:${_yamlList(archetypeDetection.signals)}

harness:
  name: steward
  mode: cli
  entrypoints:
    cli: steward

adoption:
  status: adopting
  owner: $repoId
  gate:
    pillar: quality

stewardship:
  governance:
    charter: AGENTS.md
    adr_dir: docs/decisions
  knowledge:
    docs_map: AGENTS.md
    source_policy: required_for_external_claims
  repo_quality:
    contract_spec: steward.yaml
    maturity_model: general_stewardship
  skill_lifecycle:
    installable_skills: $ownsInstallableSkills
    registry: skills.json
  quality:
    validate: $nativeValidation
    evidence: .steward/evidence
  harness:
    enabled: true
    action_contract: actions
  release:
    changelog: CHANGELOG.md
    artifact_provenance: required
  review_handoff:
    moe_required_for_architecture: true
  strategic_alignment:
    vision_source: AGENTS.md
    success_evidence: required
  security:
    action_effects: required
    redaction: steward/redaction/v1
  org:
    owners: AGENTS.md

actions:
  doctor.local:
    kind: command
    desc: Inspect Steward adoption state without running repository actions.
    command:
      argv: [steward, doctor, --json]
      shell: false
    cwd: .
    effects:
      fs_read: ["."]
      fs_write: []
      git: false
      network: false
      secrets: false
      destructive: false
    safety:
      class: observe
      default_policy: auto
      requires_confirmation: false
    limits:
      timeout_ms: 10000
      max_output_bytes: 200000
    outputs:
      - id: stdout
        kind: stream
        required: true
        retention: summary
        format: json
    evidence:
      redact: []

probes:
  quick:
    profile: quick
    actions: [doctor.local]

diagnostics:
  cases: {}

unknown_cases:
  path: .steward/unknown-cases/
  retention: local

provenance:
  dependencies: []
  artifacts: []
  benchmarks:${includeBenchmark ? '''
    - id: $repoId.contract-status-smoke
      manifest: steward/scenarios/$repoId-contract-status-smoke.yaml''' : ' []'}
'''
        .trimLeft();

String _scenarioTemplate({
  required final String repoId,
  required final _GitSourceFacts gitSource,
}) =>
    '''
schema: steward/scenario-manifest/v1
repo: $repoId
scenario: $repoId.contract-status-smoke
status: runnable
source:
  git: ${_yamlSingleQuoted(gitSource.remote)}
  commit: ${gitSource.commit}
  steward_contract: steward.yaml
safe_first_probe: doctor.local
required_actions:
  - doctor.local
artifacts:
  - id: steward_contract
    kind: yaml
    path: steward.yaml
    required: true
    durability: input
owner: $repoId
'''
        .trimLeft();

_ArchetypeDetection _detectArchetype(final String root) {
  if (File(p.join(root, 'plugin', 'mcp.json')).existsSync() ||
      File(p.join(root, 'mcp.json')).existsSync()) {
    return const _ArchetypeDetection(
      archetype: 'plugin',
      confidence: 0.8,
      signals: ['plugin/mcp.json or mcp.json'],
    );
  }
  if (File(p.join(root, 'skills.sh.json')).existsSync()) {
    return const _ArchetypeDetection(
      archetype: 'meta_governance',
      confidence: 0.8,
      signals: ['skills.sh.json'],
    );
  }
  if (Directory(p.join(root, 'tool')).existsSync() &&
      !Directory(p.join(root, 'packages')).existsSync()) {
    return const _ArchetypeDetection(
      archetype: 'cli_tool',
      confidence: 0.7,
      signals: ['tool/ without packages/'],
    );
  }
  if (Directory(p.join(root, 'apps')).existsSync() ||
      Directory(p.join(root, 'app')).existsSync() ||
      Directory(p.join(root, 'web')).existsSync() ||
      Directory(p.join(root, 'ios')).existsSync() ||
      Directory(p.join(root, 'android')).existsSync()) {
    return const _ArchetypeDetection(
      archetype: 'app',
      confidence: 0.6,
      signals: ['app runtime directory'],
    );
  }
  return const _ArchetypeDetection(
    archetype: 'library',
    confidence: 0.4,
    signals: ['default fallback'],
  );
}

String _detectNativeValidation(final String root) {
  final justfile = _firstExistingFile(root, const ['Justfile', 'justfile']);
  if (justfile != null) {
    final content = justfile.readAsStringSync();
    if (RegExp('^check:', multiLine: true).hasMatch(content)) {
      return _yamlSingleQuoted('just check');
    }
    if (RegExp('^test:', multiLine: true).hasMatch(content)) {
      return _yamlSingleQuoted('just test');
    }
  }

  final makefile = _firstExistingFile(root, const ['Makefile', 'makefile']);
  if (makefile != null) {
    final content = makefile.readAsStringSync();
    if (RegExp('^check:', multiLine: true).hasMatch(content)) {
      return _yamlSingleQuoted('make check');
    }
    if (RegExp('^test:', multiLine: true).hasMatch(content)) {
      return _yamlSingleQuoted('make test');
    }
  }

  final packageJson = File(p.join(root, 'package.json'));
  if (packageJson.existsSync()) {
    try {
      final json = jsonDecode(packageJson.readAsStringSync());
      if (json is Map && json['scripts'] is Map) {
        final scripts = json['scripts'] as Map;
        if (scripts.containsKey('validate')) {
          return _yamlSingleQuoted('pnpm run validate');
        }
        if (scripts.containsKey('test')) {
          return _yamlSingleQuoted('pnpm test');
        }
      }
    } on Object catch (_) {}
  }

  if (File(p.join(root, 'pubspec.yaml')).existsSync()) {
    return _yamlSingleQuoted('dart test');
  }
  if (File(p.join(root, 'Cargo.toml')).existsSync()) {
    return _yamlSingleQuoted('cargo test');
  }
  if (File(p.join(root, 'pyproject.toml')).existsSync()) {
    return _yamlSingleQuoted('pytest');
  }

  return _yamlSingleQuoted('blocked: native validation command not detected');
}

File? _firstExistingFile(final String root, final List<String> names) {
  for (final name in names) {
    final file = File(p.join(root, name));
    if (file.existsSync()) return file;
  }
  return null;
}

bool _ownsInstallableSkills(final String root) {
  if (File(p.join(root, 'skills.sh.json')).existsSync()) return true;
  final skillsDir = Directory(p.join(root, 'skills'));
  if (!skillsDir.existsSync()) return false;
  try {
    return skillsDir.listSync().whereType<Directory>().any(
      (final entry) => File(p.join(entry.path, 'SKILL.md')).existsSync(),
    );
  } on Object catch (_) {
    return false;
  }
}

Future<_GitSourceFacts?> _gitSourceFacts(final String root) async {
  final remote = await _gitOutput(root, [
    'config',
    '--get',
    'remote.origin.url',
  ]);
  final commit = await _gitOutput(root, ['rev-parse', 'HEAD']);
  if (remote == null || commit == null) {
    return null;
  }
  if (!_durableGitSource(remote) ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(commit)) {
    return null;
  }
  return _GitSourceFacts(remote: remote, commit: commit);
}

Future<String?> _gitOutput(
  final String root,
  final List<String> arguments,
) async {
  final result = await Process.run('git', arguments, workingDirectory: root);
  if (result.exitCode != 0) {
    return null;
  }
  final output = (result.stdout as String).trim();
  return output.isEmpty ? null : output;
}

bool _durableGitSource(final String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('https://') ||
      lower.startsWith('ssh://') ||
      RegExp(r'^[\w.-]+@[\w.-]+:.+/.+').hasMatch(value);
}

String _yamlSingleQuoted(final String value) =>
    "'${value.replaceAll("'", "''")}'";

String _yamlList(final List<String> values) {
  if (values.isEmpty) return ' []';
  return values
      .map((final value) => '\n      - ${_yamlSingleQuoted(value)}')
      .join();
}

class _ArchetypeDetection {
  const _ArchetypeDetection({
    required this.archetype,
    required this.confidence,
    required this.signals,
  });

  final String archetype;
  final double confidence;
  final List<String> signals;
}

class _GitSourceFacts {
  const _GitSourceFacts({required this.remote, required this.commit});

  final String remote;
  final String commit;
}
