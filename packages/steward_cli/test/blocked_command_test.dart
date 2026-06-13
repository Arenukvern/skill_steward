import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/blocked_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    exitCode = 0;
    tempDir = Directory.systemTemp.createTempSync('steward_blocked_test_');
    File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsStringSync(jsonEncode({'skills': []}));
  });

  tearDown(() {
    exitCode = 0;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('blocked explain turns durability block into next actions', () async {
    final input = File(p.join(tempDir.path, 'summary.json'))
      ..writeAsStringSync(
        jsonEncode({
          'schema': 'steward/benchmark-summary/v1',
          'result': 'blocked',
          'blocked_by': 'durability_blocked',
          'durability': {
            'blocking_paths': ['steward.yaml', '.steward/events.example.jsonl'],
          },
        }),
      );
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BlockedCommand(buffer, tempDir));

    await runner.run([
      'blocked',
      'explain',
      '--input',
      p.relative(input.path, from: tempDir.path),
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['schema_version'], 'steward.blocked.explain.v1');
    expect(payload['blocked_by'], 'durability_blocked');
    expect(payload['artifact_route'], 'rerun_same_benchmark_after_tracking');
    expect(payload['next_actions'], isNotEmpty);
    expect(
      payload['non_claims'],
      contains('This is blocked evidence, not proof.'),
    );
    expect(exitCode, 0);
  });

  test('blocked explain routes invalid config to config repair', () async {
    final input = File(p.join(tempDir.path, 'probe.json'))
      ..writeAsStringSync(
        jsonEncode({
          'schema_version': 'steward.probe.v1',
          'status': 'blocked_invalid_config',
          'diagnostics': [
            {'path': 'repo.archetype', 'message': 'invalid enum'},
          ],
        }),
      );
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BlockedCommand(buffer, tempDir));

    await runner.run([
      'blocked',
      'explain',
      '--input',
      p.relative(input.path, from: tempDir.path),
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['blocked_by'], 'blocked_invalid_config');
    expect(payload['artifact_route'], 'repair_config_or_unknown_case');
    expect((payload['next_actions'] as List).first, contains('steward.yaml'));
    expect(exitCode, 0);
  });

  test('blocked explain reads fresh benchmark JSON from stdin', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(
        BlockedCommand(
          buffer,
          tempDir,
          _jsonStream({
            'schema': 'steward/benchmark-summary/v1',
            'scenario': 'repo.smoke',
            'result': 'blocked',
            'blocked_by': 'durability_blocked',
            'durability': {
              'blocking_paths': ['steward.yaml'],
            },
          }),
        ),
      );

    await runner.run(['blocked', 'explain', '--stdin', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['input'], 'stdin');
    expect(payload['blocked_by'], 'durability_blocked');
    expect(
      payload['next_actions'],
      contains(
        'Rerun fresh JSON: steward benchmark --scenario repo.smoke --strict --json | steward blocked explain --stdin --json.',
      ),
    );
    expect(exitCode, 0);
  });

  test('blocked explain accepts --input - as stdin', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(
        BlockedCommand(
          buffer,
          tempDir,
          _jsonStream({
            'schema_version': 'steward.probe.v1',
            'status': 'blocked_invalid_config',
          }),
        ),
      );

    await runner.run(['blocked', 'explain', '--input', '-', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['input'], 'stdin');
    expect(payload['blocked_by'], 'blocked_invalid_config');
    expect(payload['artifact_route'], 'repair_config_or_unknown_case');
    expect(exitCode, 0);
  });

  test('benchmark invalid_config blocked_by routes to config repair', () async {
    final payload = await explainBlockedPayload(
      tempDir.path,
      inputJson: jsonEncode({
        'schema': 'steward/benchmark-summary/v1',
        'result': 'blocked',
        'blocked_by': 'invalid_config',
      }),
      inputLabel: 'stdin',
    );

    expect(payload['blocked_by'], 'blocked_invalid_config');
    expect(payload['artifact_route'], 'repair_config_or_unknown_case');
  });

  test('strict_proof_blocked uses proof blocking paths', () async {
    final payload = await explainBlockedPayload(
      tempDir.path,
      inputJson: jsonEncode({
        'schema': 'steward/benchmark-summary/v1',
        'scenario': 'repo.strict',
        'result': 'blocked',
        'blocked_by': 'strict_proof_blocked',
        'proof': {
          'status': 'blocked',
          'blocking_paths': ['NOTES.md'],
        },
      }),
      inputLabel: 'stdin',
    );

    expect(payload['blocked_by'], 'strict_proof_blocked');
    expect(
      payload['artifact_route'],
      'rerun_same_benchmark_after_strict_proof_repair',
    );
    expect(
      payload['next_actions'],
      contains('Inspect strict proof inputs: git status --short -- NOTES.md.'),
    );
  });

  test(
    'invalid stdin JSON returns fix_input_json instead of throwing',
    () async {
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(
          BlockedCommand(
            buffer,
            tempDir,
            Stream<List<int>>.value(utf8.encode('{not json')),
          ),
        );

      await runner.run(['blocked', 'explain', '--stdin', '--json']);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['blocked_by'], 'invalid_input');
      expect(payload['artifact_route'], 'fix_input_json');
      expect((payload['next_actions'] as List).first, contains('invalid'));
      expect(exitCode, 0);
    },
  );
}

Stream<List<int>> _jsonStream(final Map<String, dynamic> payload) =>
    Stream<List<int>>.value(utf8.encode(jsonEncode(payload)));
