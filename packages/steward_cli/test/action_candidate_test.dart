import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/action_candidate_command.dart';
import 'package:steward_cli/src/commands/action_command.dart';
import 'package:steward_cli/src/commands/observe_command.dart';
import 'package:steward_cli/src/commands/unknown_case_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_candidate_test_');
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

  Future<Map<String, dynamic>> createUnknownCase() async {
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
    return jsonDecode(unknownBuffer.toString()) as Map<String, dynamic>;
  }

  test('action-candidate create writes pending review record', () async {
    final unknownCase = await createUnknownCase();
    final unknownCasePath = p.join(tempDir.path, unknownCase['path'] as String);
    final unknownBefore = await File(unknownCasePath).readAsString();
    final stewardPath = p.join(tempDir.path, 'steward.yaml');
    final stewardBefore = await File(stewardPath).readAsString();
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCandidateCommand(buffer, tempDir));

    await runner.run([
      'action-candidate',
      'create',
      '--from',
      unknownCase['path'] as String,
      '--id',
      'repo.next_probe',
      '--desc',
      'Proposed next bounded probe.',
      '--argv-json',
      '["/usr/bin/touch","should-not-exist"]',
      '--benchmark',
      'sample_repo.next_probe.selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final recordPath = p.join(tempDir.path, payload['path'] as String);
    final record =
        jsonDecode(await File(recordPath).readAsString())
            as Map<String, dynamic>;
    final proposedAction = payload['proposed_action'] as Map<String, dynamic>;

    expect(payload['schema'], 'steward/action-candidate/v1');
    expect(payload['status'], 'action_candidate');
    expect(payload['path'], startsWith('.steward/action-candidates/'));
    expect(payload['review'], containsPair('status', 'pending'));
    expect(payload['review'], containsPair('promoted', false));
    expect(
      payload['promotion_gate'],
      containsPair('can_promote_in_this_run', false),
    );
    expect(proposedAction['id'], 'repo.next_probe');
    final sourceUnknownCases = record['source_unknown_cases'] as List;
    expect(sourceUnknownCases, isNotEmpty);
    expect(sourceUnknownCases.single, contains('sha256'));
    expect(
      File(p.join(tempDir.path, 'should-not-exist')).existsSync(),
      isFalse,
    );
    expect(await File(unknownCasePath).readAsString(), unknownBefore);
    expect(await File(stewardPath).readAsString(), stewardBefore);
  });

  test(
    'action-candidate review validates candidate without promotion',
    () async {
      final unknownCase = await createUnknownCase();
      final createBuffer = StringBuffer();
      final createRunner = CommandRunner<void>('steward', 'test')
        ..addCommand(ActionCandidateCommand(createBuffer, tempDir));
      await createRunner.run([
        'action-candidate',
        'create',
        '--from',
        unknownCase['path'] as String,
        '--id',
        'repo.next_probe',
        '--desc',
        'Proposed next bounded probe.',
        '--argv-json',
        '["/bin/pwd"]',
        '--benchmark',
        'sample_repo.next_probe.selection',
        '--json',
      ]);
      final candidate =
          jsonDecode(createBuffer.toString()) as Map<String, dynamic>;

      final reviewBuffer = StringBuffer();
      final reviewRunner = CommandRunner<void>('steward', 'test')
        ..addCommand(ActionCandidateCommand(reviewBuffer, tempDir));
      await reviewRunner.run([
        'action-candidate',
        'review',
        '--from',
        candidate['path'] as String,
        '--json',
      ]);

      final review =
          jsonDecode(reviewBuffer.toString()) as Map<String, dynamic>;
      expect(review['schema_version'], 'steward.action_candidate.review.v1');
      expect(review['status'], 'passed');
      expect(review['promotable'], isFalse);
      expect(review['diagnostics'], isEmpty);
    },
  );

  test('action-candidate review rejects unsafe write effects', () async {
    final unknownCase = await createUnknownCase();
    final createBuffer = StringBuffer();
    final createRunner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCandidateCommand(createBuffer, tempDir));
    await createRunner.run([
      'action-candidate',
      'create',
      '--from',
      unknownCase['path'] as String,
      '--id',
      'repo.next_probe',
      '--desc',
      'Proposed next bounded probe.',
      '--argv-json',
      '["/bin/pwd"]',
      '--benchmark',
      'sample_repo.next_probe.selection',
      '--json',
    ]);
    final candidate =
        jsonDecode(createBuffer.toString()) as Map<String, dynamic>;
    final candidateFile = File(
      p.join(tempDir.path, candidate['path'] as String),
    );
    final record =
        jsonDecode(await candidateFile.readAsString()) as Map<String, dynamic>;
    final proposedAction = record['proposed_action'] as Map<String, dynamic>;
    final effects = proposedAction['effects'] as Map<String, dynamic>;
    effects['fs_write'] = ['.git/config'];
    await candidateFile.writeAsString(jsonEncode(record));

    final reviewBuffer = StringBuffer();
    final reviewRunner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCandidateCommand(reviewBuffer, tempDir));
    await reviewRunner.run([
      'action-candidate',
      'review',
      '--from',
      candidate['path'] as String,
      '--json',
    ]);

    final review = jsonDecode(reviewBuffer.toString()) as Map<String, dynamic>;
    expect(review['status'], 'failed');
    expect(
      review['diagnostics'].toString(),
      contains('Action-candidate writes must stay under .steward/artifacts'),
    );
  });

  test('registered action inspect rejects candidate-only ids', () async {
    final unknownCase = await createUnknownCase();
    final createRunner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCandidateCommand(StringBuffer(), tempDir));
    await createRunner.run([
      'action-candidate',
      'create',
      '--from',
      unknownCase['path'] as String,
      '--id',
      'repo.next_probe',
      '--desc',
      'Proposed next bounded probe.',
      '--argv-json',
      '["/bin/pwd"]',
      '--benchmark',
      'sample_repo.next_probe.selection',
      '--json',
    ]);

    final inspectRunner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCommand(StringBuffer(), tempDir));
    expect(
      () =>
          inspectRunner.run(['action', 'inspect', 'repo.next_probe', '--json']),
      throwsA(isA<UsageException>()),
    );
  });

  test('action-candidate create rejects already declared action ids', () async {
    final unknownCase = await createUnknownCase();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCandidateCommand(StringBuffer(), tempDir));

    expect(
      () => runner.run([
        'action-candidate',
        'create',
        '--from',
        unknownCase['path'] as String,
        '--id',
        'repo.pwd',
        '--desc',
        'Duplicate declared action.',
        '--argv-json',
        '["/bin/pwd"]',
        '--benchmark',
        'sample_repo.next_probe.selection',
        '--json',
      ]),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('action-candidate create rejects outside-root unknown-case path', () {
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ActionCandidateCommand(StringBuffer(), tempDir));

    expect(
      () => runner.run([
        'action-candidate',
        'create',
        '--from',
        '../unknown.json',
        '--id',
        'repo.next_probe',
        '--desc',
        'Outside path.',
        '--argv-json',
        '["/bin/pwd"]',
        '--benchmark',
        'sample_repo.next_probe.selection',
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
