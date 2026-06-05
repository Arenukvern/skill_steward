import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/probe_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_probe_test_');
    await File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsString(jsonEncode({'skills': []}));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<Map<String, dynamic>> runProbe() async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ProbeCommand(buffer, tempDir));
    await runner.run(['probe', '--json', '--profile', 'quick']);
    return jsonDecode(buffer.toString()) as Map<String, dynamic>;
  }

  test('quick probe with no actions returns no_actions', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(quickActions: const []));

    final payload = await runProbe();

    expect(payload['schema_version'], 'steward.probe.v1');
    expect(payload['status'], 'no_actions');
    expect(payload['executions'], isEmpty);
  });

  test('quick probe runs a safe bounded local action', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());

    final payload = await runProbe();
    final executions = payload['executions'] as List;
    final execution = executions.single as Map<String, dynamic>;

    expect(payload['status'], 'passed');
    expect(execution['action_id'], 'repo.pwd');
    expect(execution['exit_code'], 0);
    expect(execution['stdout'], contains(tempDir.path));
  });

  test('quick probe rejects unsafe actions without executing them', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(unsafeQuickStewardV1());

    final payload = await runProbe();
    final rejections = payload['rejections'] as List;
    final rejection = rejections.single as Map<String, dynamic>;

    expect(payload['config_valid'], isFalse);
    expect(payload['status'], 'blocked_invalid_config');
    expect(payload['executions'], isEmpty);
    expect(rejection['action_id'], 'repo.external');
    expect(rejection['reason_code'], 'quick_policy_violation');
    expect(
      rejection['inspect_ref'],
      'steward action inspect repo.external --json',
    );
  });
}

String validStewardV1({final List<String> quickActions = const ['repo.pwd']}) {
  final actionList = quickActions.join(', ');
  return '''
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
  repo.pwd:
    kind: command
    desc: Print current working directory.
    command:
      argv: [/bin/pwd]
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
      class: bounded_local
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
        format: text
    evidence:
      redact: []
probes:
  quick:
    profile: quick
    actions: [$actionList]
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
}

String unsafeQuickStewardV1() => '''
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
  repo.external:
    kind: command
    desc: Unsafe quick action.
    command:
      argv: [/bin/sh, -c, "touch should-not-exist"]
      shell: true
    cwd: .
    effects:
      fs_read: ["."]
      fs_write: ["should-not-exist"]
      git: write
      network: true
      secrets: true
      destructive: false
    safety:
      class: external
      default_policy: confirm
      requires_confirmation: true
    limits:
      timeout_ms: 20000
      max_output_bytes: 200000
    outputs:
      - id: stdout
        kind: stream
        required: true
        retention: summary
        format: text
    evidence:
      redact: []
probes:
  quick:
    profile: quick
    actions: [repo.external]
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
