import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/diagnose_command.dart';
import 'package:steward_cli/src/commands/observe_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_diagnose_test_');
    await File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsString(jsonEncode({'skills': []}));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<Map<String, dynamic>> createObservation() async {
    final observeBuffer = StringBuffer();
    final observeRunner = CommandRunner<void>('steward', 'test')
      ..addCommand(ObserveCommand(observeBuffer, tempDir));
    await observeRunner.run(['observe', '--json']);
    return jsonDecode(observeBuffer.toString()) as Map<String, dynamic>;
  }

  test('diagnose returns unknown_case without promoted diagnostics', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
    final observation = await createObservation();
    final beforeEntries = Directory(
      p.join(tempDir.path, '.steward'),
    ).listSync(recursive: true).map((final entity) => entity.path).toSet();
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(DiagnoseCommand(buffer, tempDir));

    await runner.run([
      'diagnose',
      '--from',
      observation['path'] as String,
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final afterEntries = Directory(
      p.join(tempDir.path, '.steward'),
    ).listSync(recursive: true).map((final entity) => entity.path).toSet();
    expect(payload['schema_version'], 'steward.diagnose.v1');
    expect(payload['status'], 'unknown_case');
    expect(payload['diagnosis'], isNull);
    expect(payload['confidence'], 0);
    expect(payload['known_cases'], 0);
    expect(payload['input_observation'], contains('sha256'));
    expect(payload['next_probes'], ['repo.pwd']);
    expect(payload['capture'], contains('recommended_path'));
    expect(payload['capture'], containsPair('recommended', true));
    expect(payload['capture'], contains('command'));
    expect(afterEntries, beforeEntries);
  });

  test('diagnose matches only promoted diagnostics', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(promotedDiagnostic: true));
    final observation = await createObservation();
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(DiagnoseCommand(buffer, tempDir));

    await runner.run([
      'diagnose',
      '--from',
      observation['path'] as String,
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final diagnosis = payload['diagnosis'] as Map<String, dynamic>;
    expect(payload['status'], 'matched');
    expect(payload['known_cases'], 1);
    expect(payload['confidence'], 0.9);
    expect(diagnosis['diagnostic_id'], 'repo-pwd-passed-v1');
    expect(diagnosis['linked_actions'], ['repo.pwd']);
    expect(payload['capture'], isNull);
  });

  test('diagnose ignores candidate diagnostics', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(candidateDiagnostic: true));
    final observation = await createObservation();
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(DiagnoseCommand(buffer, tempDir));

    await runner.run([
      'diagnose',
      '--from',
      observation['path'] as String,
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['status'], 'unknown_case');
    expect(payload['diagnosis'], isNull);
    expect(payload['known_cases'], 0);
  });

  test(
    'diagnose returns unknown_case for ambiguous promoted matches',
    () async {
      await File(p.join(tempDir.path, 'steward.yaml')).writeAsString(
        validStewardV1(promotedDiagnostic: true, ambiguous: true),
      );
      final observation = await createObservation();
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(DiagnoseCommand(buffer, tempDir));

      await runner.run([
        'diagnose',
        '--from',
        observation['path'] as String,
        '--json',
      ]);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['status'], 'unknown_case');
      expect(payload['diagnosis'], isNull);
      expect(payload['known_cases'], 2);
      expect(payload['matches'], hasLength(2));
      expect(
        payload['diagnostics'].toString(),
        contains('ambiguous_promoted_match'),
      );
    },
  );

  test(
    'diagnose refuses promoted diagnostics with missing promotion proof',
    () async {
      await File(p.join(tempDir.path, 'steward.yaml')).writeAsString(
        validStewardV1(promotedDiagnostic: true, missingReview: true),
      );
      final observation = await createObservation();
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(DiagnoseCommand(buffer, tempDir));

      await runner.run([
        'diagnose',
        '--from',
        observation['path'] as String,
        '--json',
      ]);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['status'], 'unknown_case');
      expect(payload['diagnosis'], isNull);
      expect(payload['known_cases'], 1);
      expect(payload['diagnostics'].toString(), contains('review owner'));
    },
  );

  test('diagnose rejects observation paths outside repository root', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(DiagnoseCommand(StringBuffer(), tempDir));

    expect(
      () => runner.run(['diagnose', '--from', '../outside.json', '--json']),
      throwsA(isA<ArgumentError>()),
    );
  });
}

String validStewardV1({
  final bool promotedDiagnostic = false,
  final bool candidateDiagnostic = false,
  final bool ambiguous = false,
  final bool missingReview = false,
}) {
  final diagnosticStatus = promotedDiagnostic
      ? 'promoted_diagnostic'
      : candidateDiagnostic
      ? 'candidate_diagnostic'
      : null;
  final diagnosticYaml = diagnosticStatus == null
      ? null
      : '''
  repo-pwd-passed-v1:
    diagnostic_id: repo-pwd-passed-v1
    status: $diagnosticStatus
    repo: sample_repo
    source_unknown_cases:
      - unknown-existing
    detection:
      confidence_threshold: 0.8
      confidence: 0.9
      predicates:
        - kind: status_equals
          value: passed
        - kind: action_id_equals
          value: repo.pwd
    linked_actions:
      - repo.pwd
    verification:
      held_out_benchmarks:
        - sample_repo.pwd-held-out
    review:
      owner: sample_repo
      ${missingReview ? '' : 'approved_by: maintainer'}
      ${missingReview ? '' : 'approved_at: "2026-06-05T10:30:00Z"'}
    provenance:
      first_seen: unknown-existing
      source: fixture
${ambiguous ? '''
  repo-pwd-passed-v2:
    diagnostic_id: repo-pwd-passed-v2
    status: promoted_diagnostic
    repo: sample_repo
    source_unknown_cases:
      - unknown-existing-2
    detection:
      confidence_threshold: 0.8
      confidence: 0.9
      predicates:
        - kind: status_equals
          value: passed
        - kind: action_id_equals
          value: repo.pwd
    linked_actions:
      - repo.pwd
    verification:
      held_out_benchmarks:
        - sample_repo.pwd-held-out-2
    review:
      owner: sample_repo
      approved_by: maintainer
      approved_at: "2026-06-05T11:30:00Z"
    provenance:
      first_seen: unknown-existing-2
      source: fixture
''' : ''}
''';
  final indentedDiagnosticYaml = diagnosticYaml
      ?.split('\n')
      .map((final line) => line.isEmpty ? line : '  $line')
      .join('\n');
  final casesYaml = indentedDiagnosticYaml == null
      ? '  cases: {}'
      : '''
  cases:
$indentedDiagnosticYaml''';

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
    actions: [repo.pwd]
diagnostics:
$casesYaml
unknown_cases:
  path: .steward/unknown-cases/
  retention: local
provenance:
  dependencies: []
  artifacts: []
  benchmarks: []
''';
}
