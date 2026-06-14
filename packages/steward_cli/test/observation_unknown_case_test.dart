import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/observe_command.dart';
import 'package:steward_cli/src/commands/unknown_case_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_observe_test_');
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

  test('observe --json writes a compact observation record', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ObserveCommand(buffer, tempDir));

    await runner.run(['observe', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final observationPath = p.join(tempDir.path, payload['path'] as String);
    final observation =
        jsonDecode(await File(observationPath).readAsString())
            as Map<String, dynamic>;

    expect(payload['schema'], 'steward/observation/v1');
    expect(payload['path'], startsWith('.steward/observations/'));
    expect(File(observationPath).existsSync(), isTrue);
    expect(observation['id'], payload['id']);
    expect(observation['summary'], containsPair('status', 'passed'));
  });

  test(
    'unknown-case create writes append-only unknown-case evidence',
    () async {
      final observeBuffer = StringBuffer();
      final observeRunner = CommandRunner<void>('steward', 'test')
        ..addCommand(ObserveCommand(observeBuffer, tempDir));
      await observeRunner.run(['observe', '--json']);
      final observation =
          jsonDecode(observeBuffer.toString()) as Map<String, dynamic>;

      final unknownBuffer = StringBuffer();
      final unknownRunner = CommandRunner<void>('steward', 'test')
        ..addCommand(UnknownCaseCommand(unknownBuffer, tempDir));
      await unknownRunner.run([
        'unknown-case',
        'create',
        '--from',
        observation['path'] as String,
        '--json',
      ]);

      final payload =
          jsonDecode(unknownBuffer.toString()) as Map<String, dynamic>;
      final unknownPath = p.join(tempDir.path, payload['path'] as String);
      final record =
          jsonDecode(await File(unknownPath).readAsString())
              as Map<String, dynamic>;

      expect(payload['schema'], 'steward/unknown-case/v1');
      expect(payload['status'], 'unknown_case');
      expect(payload.containsKey('diagnosis'), isFalse);
      expect(payload.containsKey('confidence'), isFalse);
      expect(payload['review'], containsPair('status', 'pending'));
      expect(payload['review'], containsPair('promoted', false));
      expect(
        record['source_observation'],
        containsPair('id', observation['id']),
      );
      expect(record['source_observation'], contains('sha256'));
      expect(payload['path'], startsWith('.steward/unknown-cases/'));
    },
  );

  test('unknown-case create rejects paths outside repository root', () {
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(UnknownCaseCommand(StringBuffer(), tempDir));

    expect(
      () => runner.run([
        'unknown-case',
        'create',
        '--from',
        '../outside.json',
        '--json',
      ]),
      throwsA(isA<ArgumentError>()),
    );
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
    actions: [repo.pwd]
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
