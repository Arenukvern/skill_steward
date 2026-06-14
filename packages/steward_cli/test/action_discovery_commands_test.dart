import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/action_command.dart';
import 'package:steward_cli/src/commands/actions_command.dart';
import 'package:steward_cli/src/commands/doctor_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_actions_test_');
    await File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsString(jsonEncode({'skills': []}));
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'doctor --json emits adoption inventory without running actions',
    () async {
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(DoctorCommand(buffer, tempDir));

      await runner.run(['doctor', '--json']);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['schema_version'], 'steward.doctor.v1');
      expect(payload['config'], containsPair('valid', true));
      expect(payload['actions'], isNotEmpty);
    },
  );

  test('actions list --json emits typed action summaries', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionsCommand(buffer, tempDir));

    await runner.run(['actions', 'list', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final actions = payload['actions'] as List;
    expect(payload['schema_version'], 'steward.actions.v1');
    expect(actions.single, containsPair('id', 'doctor.local'));
  });

  test('action inspect --json emits one exact action contract', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCommand(buffer, tempDir));

    await runner.run(['action', 'inspect', 'doctor.local', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final action = payload['action'] as Map<String, dynamic>;
    expect(payload['schema_version'], 'steward.action.v1');
    expect(action['id'], 'doctor.local');
    expect(action['command'], isA<Map>());
  });
}

String validStewardV1() => '''
schema: steward/v1
repo:
  id: sample_repo
  archetype: cli_tool
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
  repo_quality:
    contract_spec: steward.yaml
    maturity_model: general_stewardship
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
