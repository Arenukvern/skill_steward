import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/validation/validation.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('steward_v1_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> writeSkillsJson() async {
    await File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsString(jsonEncode({'skills': []}));
  }

  Future<void> writeStewardYaml(final String content) async {
    await File(p.join(tempDir.path, 'steward.yaml')).writeAsString(content);
  }

  test('loads valid steward/v1 contract with typed actions', () async {
    await writeStewardYaml(validStewardV1());

    final result = await StewardConfig.loadChecked(tempDir.path);

    expect(result.ok, isTrue);
    expect(result.config.isV1, isTrue);
    expect(result.config.repo['id'], 'sample_repo');
    expect(result.config.typedActions.single.id, 'doctor.local');
  });

  test('reports malformed steward.yaml instead of swallowing it', () async {
    await writeStewardYaml('schema: [');

    final result = await StewardConfig.loadChecked(tempDir.path);

    expect(result.ok, isFalse);
    expect(result.diagnostics.single.path, 'steward.yaml');
  });

  test('rejects missing required steward/v1 sections', () async {
    await writeStewardYaml('''
schema: steward/v1
repo:
  id: sample_repo
''');

    final result = await StewardConfig.loadChecked(tempDir.path);

    expect(result.ok, isFalse);
    expect(
      result.diagnostics.map((final diagnostic) => diagnostic.path),
      contains('harness'),
    );
  });

  test('rejects probe references to unknown actions', () async {
    await writeStewardYaml(
      validStewardV1().replaceFirst(
        'actions: [doctor.local]',
        'actions: [missing.action]',
      ),
    );

    final result = await StewardConfig.loadChecked(tempDir.path);

    expect(result.ok, isFalse);
    expect(
      result.diagnostics.map((final diagnostic) => diagnostic.message),
      contains('Probe references unknown action "missing.action".'),
    );
  });

  test('rejects unsafe actions declared in quick probes', () async {
    await writeStewardYaml(
      validStewardV1().replaceFirst(
        '''
      shell: false''',
        '''
      shell: true''',
      ),
    );

    final result = await StewardConfig.loadChecked(tempDir.path);

    expect(result.ok, isFalse);
    expect(
      result.diagnostics
          .map((final diagnostic) => diagnostic.message)
          .join('\n'),
      contains('Quick probe action "doctor.local" violates policy'),
    );
  });

  test('validateLocalSkills rejects legacy pipeline command under v1', () async {
    await writeSkillsJson();
    await writeStewardYaml('''
${validStewardV1()}
pipelines:
  validate:
    cmd: pnpm run validate
''');

    final report = await validateLocalSkills(tempDir.path);

    expect(report.ok, isFalse);
    expect(
      report.registryWarnings,
      contains(
        'pipelines.validate.cmd: schema: steward/v1 forbids legacy pipelines.*.cmd; declare actions.*.command.argv instead.',
      ),
    );
  });

  test('loads valid benchmark scenario manifest file', () async {
    final scenario = File(
      p.join(tempDir.path, 'steward', 'scenarios', 'sample.yaml'),
    )..createSync(recursive: true);
    await scenario.writeAsString(validScenarioManifest());
    await writeStewardYaml(
      validStewardV1().replaceFirst('benchmarks: []', '''
benchmarks:
    - id: sample_repo.doctor
      manifest: steward/scenarios/sample.yaml'''),
    );

    final result = await StewardConfig.loadChecked(tempDir.path);

    expect(result.ok, isTrue);
  });

  test('rejects non-durable benchmark scenario manifests under v1', () async {
    await writeStewardYaml(
      validStewardV1().replaceFirst('benchmarks: []', '''
benchmarks:
    - schema: steward/scenario-manifest/v1
      repo: sample_repo
      scenario: sample_repo.doctor
      status: runnable
      source:
        git: /Users/anton/local-only
        commit: main
        steward_contract: /tmp/steward.yaml
      safe_first_probe: missing.action
      required_actions:
        - missing.action
      artifacts:
        - id: steward_contract
          kind: yaml
          path: ../steward.yaml
          required: yes
      blocked_by: null
      owner: sample_repo'''),
    );

    final result = await StewardConfig.loadChecked(tempDir.path);
    final diagnostics = result.diagnostics
        .map((final diagnostic) => '${diagnostic.path}: ${diagnostic.message}')
        .join('\n');

    expect(result.ok, isFalse);
    expect(diagnostics, contains('source.git must be a durable git URL'));
    expect(diagnostics, contains('source.commit must be a resolved'));
    expect(
      diagnostics,
      contains('safe_first_probe references unknown action "missing.action"'),
    );
    expect(
      diagnostics,
      contains('required_actions references unknown action "missing.action"'),
    );
    expect(diagnostics, contains('Artifact required must be a boolean'));
    expect(diagnostics, contains('Artifact paths must be relative paths'));
  });
}

String validScenarioManifest() => '''
schema: steward/scenario-manifest/v1
repo: sample_repo
scenario: sample_repo.doctor
status: runnable
source:
  git: https://example.invalid/sample_repo.git
  commit: 0123456789abcdef0123456789abcdef01234567
  steward_contract: steward.yaml
safe_first_probe: doctor.local
required_actions:
  - doctor.local
artifacts:
  - id: steward_contract
    kind: yaml
    path: steward.yaml
    required: true
blocked_by: null
owner: sample_repo
''';

String validStewardV1() => '''
schema: steward/v1
repo:
  id: sample_repo
  archetype: cli_harness
harness:
  name: steward
  mode: cli
  entrypoints:
    cli: steward
adoption:
  status: adopting
  owner: sample_repo
  gate:
    pillar: quality

stewardship:
  governance:
    charter: AGENTS.md
  knowledge:
    docs_map: AGENTS.md
  skill_lifecycle:
    installable_skills: true
  quality:
    validate: steward validate
  harness:
    enabled: true
  release:
    changelog: CHANGELOG.md
  review_handoff:
    moe_required_for_architecture: true
  strategic_alignment:
    vision_source: AGENTS.md
  security:
    action_effects: required
  org:
    owners: AGENTS.md
actions:
  doctor.local:
    kind: command
    desc: Inspect Steward adoption state.
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
  benchmarks: []
''';
