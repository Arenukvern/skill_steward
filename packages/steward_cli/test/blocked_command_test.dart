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
}
