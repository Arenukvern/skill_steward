import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/claim_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    exitCode = 0;
    tempDir = Directory.systemTemp.createTempSync('steward_claim_test_');
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

  test('command JSON output passes valid protocol claim evidence', () async {
    final evidence = File(p.join(tempDir.path, 'evidence.md'))
      ..writeAsStringSync('''
status: stewardship_protocol
mode rules exist
memory boundaries exist
handoff rules exist
evidence gates exist
non-claims are documented
''');
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ClaimCommand(buffer, tempDir));

    await runner.run([
      'claim',
      'check',
      '--claim',
      'stewardship_protocol',
      '--evidence',
      p.relative(evidence.path, from: tempDir.path),
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;

    expect(payload['schema_version'], 'steward.claim.check.v1');
    expect(payload['claim'], 'stewardship_protocol');
    expect(payload['valid'], isTrue);
    expect(payload['result'], 'not_rejected');
    expect(payload['accepted'], isFalse);
    expect(exitCode, 0);
  });

  test('command JSON output fails overclaim evidence', () async {
    final evidence = File(p.join(tempDir.path, 'evidence.md'))
      ..writeAsStringSync('pnpm run validate passed.');
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ClaimCommand(buffer, tempDir));

    await runner.run([
      'claim',
      'check',
      '--claim',
      'proven_repo_steward',
      '--evidence',
      p.relative(evidence.path, from: tempDir.path),
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;

    expect(payload['valid'], isFalse);
    expect(payload['result'], 'rejected');
    expect(payload['accepted'], isFalse);
    expect(payload['diagnostics'], isNotEmpty);
    expect(payload['non_claims'], isNotEmpty);
    expect(exitCode, 1);
  });
}
