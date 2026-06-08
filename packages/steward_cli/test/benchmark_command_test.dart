import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/benchmark_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_benchmark_test_');
    await File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsString(jsonEncode({'skills': []}));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('benchmark runs only required runnable actions', () async {
    final stewardFile = File(p.join(tempDir.path, 'steward.yaml'));
    await stewardFile.writeAsString(validStewardV1());
    await _initGitRepo(tempDir);
    await _commitAll(tempDir, 'benchmark inputs');
    final stewardBefore = await stewardFile.readAsString();
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['schema'], 'steward/benchmark-summary/v1');
    expect(payload['scenario'], 'sample_repo.pwd-selection');
    expect(payload['result'], 'pass');
    expect(payload['durability'], containsPair('status', 'ready'));
    expect('${payload['runner']}', startsWith('steward@'));
    expect(payload['actions_run'], ['repo.pwd']);
    final trace = payload['selection_trace'] as Map<String, dynamic>;
    expect(trace['safe_first_probe'], containsPair('status', 'accepted'));
    expect(trace['considered_actions'], ['repo.pwd']);
    expect(trace['selected_actions'], ['repo.pwd']);
    expect(trace['rejected_actions'], isEmpty);
    expect(payload.containsKey('executions'), isFalse);
    final executionSummaries = payload['execution_summaries'] as List;
    expect(executionSummaries.single, contains('stdout_sha256'));
    expect(executionSummaries.single, isNot(contains('stdout')));
    expect(executionSummaries.single, isNot(contains('stderr')));
    final artifacts = payload['artifacts'] as List;
    expect(artifacts.single, containsPair('present', true));
    expect(artifacts.single, contains('sha256'));
    expect(await stewardFile.readAsString(), stewardBefore);
  });

  test('strict benchmark blocks dirty broad-read actions', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
    await _initGitRepo(tempDir);
    await _commitAll(tempDir, 'clean benchmark inputs');
    await File(p.join(tempDir.path, 'NOTES.md')).writeAsString('dirty note\n');
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--strict',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['result'], 'blocked');
    expect(payload['blocked_by'], 'strict_proof_blocked');
    expect(payload['actions_run'], isEmpty);
    final proof = payload['proof'] as Map<String, dynamic>;
    expect(proof['mode'], 'strict');
    expect(proof['status'], 'blocked');
    expect(proof['broad_read_actions'], ['repo.pwd']);
    expect(proof['blocking_paths'], contains('NOTES.md'));
  });

  test('benchmark writes compact summary artifact', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
    await _initGitRepo(tempDir);
    await _commitAll(tempDir, 'clean benchmark inputs');
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));
    const outputPath = '.steward/benchmark-summaries/pwd-selection.json';

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--strict',
      '--output',
      outputPath,
      '--json',
    ]);

    final stdoutPayload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final outputFile = File(p.join(tempDir.path, outputPath));
    expect(outputFile.existsSync(), isTrue);
    final artifactPayload =
        jsonDecode(await outputFile.readAsString()) as Map<String, dynamic>;
    expect(artifactPayload['run_id'], stdoutPayload['run_id']);
    expect(artifactPayload['result'], 'pass');
    expect(artifactPayload['proof'], containsPair('mode', 'strict'));
    expect(artifactPayload.containsKey('executions'), isFalse);
    final executionSummaries = artifactPayload['execution_summaries'] as List;
    expect(executionSummaries.single, isNot(contains('stdout')));
    expect(executionSummaries.single, isNot(contains('stderr')));
  });

  test('benchmark loads scenario manifests from repo files', () async {
    final scenarioFile = File(
      p.join(tempDir.path, 'steward', 'scenarios', 'pwd-selection.yaml'),
    )..createSync(recursive: true);
    await scenarioFile.writeAsString(scenarioManifestYaml());
    await File(p.join(tempDir.path, 'steward.yaml')).writeAsString(
      validStewardV1(manifestPath: 'steward/scenarios/pwd-selection.yaml'),
    );
    await _initGitRepo(tempDir);
    await _commitAll(tempDir, 'file backed scenario');
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['result'], 'pass');
    expect(
      payload['scenario_manifest'],
      'steward/scenarios/pwd-selection.yaml',
    );
    expect(
      payload['scenario_manifest_sha256'],
      matches(RegExp(r'^[a-f0-9]{64}$')),
    );
    expect(payload['input_digests'], contains('scenario_manifest'));
    expect(payload['durability'], containsPair('status', 'ready'));
  });

  test(
    'benchmark blocks uncommitted contract inputs before execution',
    () async {
      await _initGitRepo(tempDir);
      await File(p.join(tempDir.path, 'README.md')).writeAsString('seed');
      await _git(tempDir, ['add', 'README.md']);
      await _git(tempDir, ['commit', '-m', 'seed']);
      final sourceCommit = (await _git(tempDir, ['rev-parse', 'HEAD'])).trim();
      await File(
        p.join(tempDir.path, 'steward.yaml'),
      ).writeAsString(validStewardV1(sourceCommit: sourceCommit));

      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(BenchmarkCommand(buffer, tempDir));

      await runner.run([
        'benchmark',
        '--scenario',
        'sample_repo.pwd-selection',
        '--json',
      ]);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['result'], 'blocked');
      expect(payload['blocked_by'], 'durability_blocked');
      expect(payload['actions_run'], isEmpty);
      final durability = payload['durability'] as Map<String, dynamic>;
      expect(durability['status'], 'blocked');
      expect(durability['blocking_paths'], contains('steward.yaml'));
      expect(durability['warnings'].toString(), contains('dirty files'));
    },
  );

  test('benchmark blocks dirty input artifacts before execution', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(artifactPath: 'tool/agent.dart'));
    final toolFile = File(p.join(tempDir.path, 'tool', 'agent.dart'))
      ..createSync(recursive: true);
    await toolFile.writeAsString('void main() {}\n');
    await _initGitRepo(tempDir);
    await _commitAll(tempDir, 'clean benchmark inputs');
    await toolFile.writeAsString('void main() { print("dirty"); }\n');

    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['result'], 'blocked');
    expect(payload['blocked_by'], 'durability_blocked');
    expect(payload['actions_run'], isEmpty);
    final inputDigests = payload['input_digests'] as Map<String, dynamic>;
    expect(
      (inputDigests['artifact:steward_contract'] as Map)['sha256'],
      matches(RegExp(r'^[a-f0-9]{64}$')),
    );
    final durability = payload['durability'] as Map<String, dynamic>;
    expect(durability['blocking_paths'], contains('tool/agent.dart'));
  });

  test('benchmark blocks planned scenarios without execution', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(status: 'planned'));
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['result'], 'blocked');
    expect(payload['blocked_by'], 'scenario_planned');
    expect(payload['actions_run'], isEmpty);
  });

  test('benchmark rejects unsafe required actions without execution', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(unsafeAction: true));
    final sentinel = File(p.join(tempDir.path, 'should-not-exist'));
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final trace = payload['selection_trace'] as Map<String, dynamic>;
    expect(payload['result'], 'blocked');
    expect(payload['actions_run'], isEmpty);
    expect(trace['rejected_actions'].toString(), contains('unsafe_action'));
    expect(sentinel.existsSync(), isFalse);
  });

  test('benchmark blocks unknown safe_first_probe without execution', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(safeFirstProbe: 'missing.probe'));
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    final trace = payload['selection_trace'] as Map<String, dynamic>;
    expect(payload['result'], 'blocked');
    expect(payload['actions_run'], isEmpty);
    expect(trace['safe_first_probe'], containsPair('status', 'rejected'));
    expect(
      trace['rejected_actions'].toString(),
      contains('invalid_safe_first_probe'),
    );
  });

  test('benchmark fails when required artifact is missing', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1(artifactPath: 'missing-artifact.json'));
    await _initGitRepo(tempDir);
    await _commitAll(tempDir, 'missing artifact scenario');
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(buffer, tempDir));

    await runner.run([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['result'], 'fail');
    expect(payload['artifacts'].toString(), contains('present: false'));
  });

  test('benchmark reports unknown scenarios as usage errors', () async {
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BenchmarkCommand(StringBuffer(), tempDir));

    expect(
      () => runner.run([
        'benchmark',
        '--scenario',
        'sample_repo.missing',
        '--json',
      ]),
      throwsA(isA<UsageException>()),
    );
  });
}

String validStewardV1({
  final String status = 'runnable',
  final bool unsafeAction = false,
  final String safeFirstProbe = 'repo.pwd',
  final String artifactPath = 'steward.yaml',
  final String? manifestPath,
  final String sourceCommit = '0123456789abcdef0123456789abcdef01234567',
}) {
  final commandArgv = unsafeAction
      ? '[/usr/bin/touch, should-not-exist]'
      : '[/bin/pwd]';
  final shell = unsafeAction ? 'true' : 'false';
  final benchmarks = manifestPath == null
      ? '''
    - ${scenarioManifestYaml(status: status, safeFirstProbe: safeFirstProbe, artifactPath: artifactPath, sourceCommit: sourceCommit).trim().replaceAll('\n', '\n      ')}
'''
      : '''
    - id: sample_repo.pwd-selection
      manifest: $manifestPath
''';
  return '''
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
      argv: $commandArgv
      shell: $shell
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
    actions: []
diagnostics:
  cases: {}
unknown_cases:
  path: .steward/unknown-cases/
  retention: local
provenance:
  dependencies: []
  artifacts: []
  benchmarks:
$benchmarks
''';
}

String scenarioManifestYaml({
  final String status = 'runnable',
  final String safeFirstProbe = 'repo.pwd',
  final String artifactPath = 'steward.yaml',
  final String sourceCommit = '0123456789abcdef0123456789abcdef01234567',
}) =>
    '''
schema: steward/scenario-manifest/v1
repo: sample_repo
scenario: sample_repo.pwd-selection
status: $status
source:
  git: https://example.invalid/sample_repo.git
  commit: $sourceCommit
  steward_contract: steward.yaml
safe_first_probe: $safeFirstProbe
required_actions:
  - repo.pwd
artifacts:
  - id: steward_contract
    kind: yaml
    path: $artifactPath
    required: true
    durability: input
blocked_by: ${status == 'blocked' ? 'test-blocker' : 'null'}
owner: sample_repo
''';

Future<void> _initGitRepo(final Directory dir) async {
  await _git(dir, ['init']);
  await _git(dir, ['config', 'user.email', 'steward@example.invalid']);
  await _git(dir, ['config', 'user.name', 'Steward Test']);
}

Future<void> _commitAll(final Directory dir, final String message) async {
  await _git(dir, ['add', '.']);
  await _git(dir, ['commit', '-m', message]);
}

Future<String> _git(final Directory dir, final List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: dir.path);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
  return result.stdout.toString();
}
