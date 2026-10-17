import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/eval/eval.dart';
import 'package:test/test.dart';

import 'action_discovery_commands_test.dart'
    show networkActionStewardV1, validStewardV1;
import 'benchmark_command_test.dart' as benchmark_fixture;

void main() {
  final packageRoot = Directory.current.path;
  late Directory executableRoot;
  late String nativeCli;
  setUpAll(() async {
    executableRoot = Directory.systemTemp.createTempSync(
      'steward_exit_binary_',
    );
    nativeCli = p.join(executableRoot.path, 'steward');
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'exe',
      p.join(packageRoot, 'bin/steward.dart'),
      '-o',
      nativeCli,
    ]);
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout} ${compiled.stderr}',
    );
  });
  tearDownAll(() => executableRoot.deleteSync(recursive: true));
  late Directory root;
  setUp(() {
    root = Directory.systemTemp.createTempSync('steward_exit_');
    File(p.join(root.path, 'skills.json')).writeAsStringSync('{"skills":[]}');
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> cli(final List<String> args) =>
      Process.run(nativeCli, args, workingDirectory: root.path);

  for (final json in [false, true]) {
    test('action failure propagates, json=$json', () async {
      File(p.join(root.path, 'steward.yaml')).writeAsStringSync(
        validStewardV1().replaceFirst(
          'argv: [steward, doctor, --json]',
          'argv: [/bin/sh, -c, "echo failure >&2; exit 7"]',
        ),
      );
      final result = await cli([
        'action',
        'run',
        'doctor.local',
        if (json) '--json',
      ]);
      expect(result.exitCode, 7);
      if (json) {
        final payload = jsonDecode(result.stdout as String) as Map;
        expect(payload['status'], 'failed');
        expect((payload['execution'] as Map)['stderr'], contains('failure'));
      }
    });
  }

  test('probe failure and missing probe return nonzero', () async {
    final config = validStewardV1().replaceFirst(
      'argv: [steward, doctor, --json]',
      'argv: [/bin/sh, -c, "exit 7"]',
    );
    File(p.join(root.path, 'steward.yaml')).writeAsStringSync(config);
    expect((await cli(['probe', '--json'])).exitCode, isNonZero);
    File(p.join(root.path, 'steward.yaml')).writeAsStringSync(
      config.replaceFirst('profile: quick', 'profile: absent'),
    );
    expect((await cli(['probe', '--json'])).exitCode, isNonZero);
  });

  test('successful action still exits zero', () async {
    File(p.join(root.path, 'steward.yaml')).writeAsStringSync(
      validStewardV1().replaceFirst(
        'argv: [steward, doctor, --json]',
        'argv: [/bin/sh, -c, "exit 0"]',
      ),
    );
    expect(
      (await cli(['action', 'run', 'doctor.local', '--json'])).exitCode,
      0,
    );
  });

  test('explicit non-T1 cases execute and failures fail', () async {
    final skill = Directory(p.join(root.path, 'skills', 'optional-skill'))
      ..createSync(recursive: true);
    File(p.join(skill.path, 'SKILL.md')).writeAsStringSync(
      '---\nname: optional-skill\ndescription: Test fixture\n---\n',
    );
    final cases = Directory(p.join(skill.path, 'evals', 'cases'))
      ..createSync(recursive: true);
    File(p.join(cases.path, 'missing.yaml')).writeAsStringSync('''
id: missing
skill: optional-skill
routing: should_trigger
input: test fixture
rules:
  - kind: file_exists
    path: missing.md
''');
    final report = await evalAllSkills(
      p.join(root.path, 'skills'),
      targets: ['optional-skill'],
    );
    expect(report.results.single.total, 1);
    expect(report.ok, false);
    expect((await cli(['eval', 'optional-skill', '--json'])).exitCode, 1);
  });

  test(
    'explicit skill without cases is skipped, never a zero-case pass',
    () async {
      Directory(
        p.join(root.path, 'skills', 'optional-skill'),
      ).createSync(recursive: true);
      final result = await cli(['eval', 'optional-skill', '--json']);
      final payload = jsonDecode(result.stdout as String) as Map;
      expect(result.exitCode, 1);
      expect(((payload['results'] as List).single as Map)['status'], 'skipped');
      final text = await cli(['eval', 'optional-skill']);
      expect(text.stdout, contains('skipped'));
      expect(text.stdout, isNot(contains('0/0 cases passed')));
    },
  );
  test('rejected actions fail without execution', () async {
    File(
      p.join(root.path, 'steward.yaml'),
    ).writeAsStringSync(networkActionStewardV1());
    final result = await cli(['action', 'run', 'repo.network', '--json']);
    expect(result.exitCode, isNonZero);
    final payload = jsonDecode(result.stdout as String) as Map;
    expect(payload['status'], 'rejected');
    expect(payload['execution'], isNull);
  });

  test('blocked benchmark returns nonzero and retains its receipt', () async {
    File(
      p.join(root.path, 'steward.yaml'),
    ).writeAsStringSync(benchmark_fixture.validStewardV1());
    final result = await cli([
      'benchmark',
      '--scenario',
      'sample_repo.pwd-selection',
      '--strict',
      '--json',
    ]);
    expect(result.exitCode, isNonZero);
    final payload = jsonDecode(result.stdout as String) as Map;
    expect(payload['result'], 'blocked');
  });

  test('optional passing cases are discovered in default evals', () async {
    final cases = Directory(
      p.join(root.path, 'skills', 'optional-skill', 'evals', 'cases'),
    )..createSync(recursive: true);
    File(
      p.join(root.path, 'skills', 'optional-skill', 'SKILL.md'),
    ).writeAsStringSync(
      '---\nname: optional-skill\ndescription: Optional fixture\n---\n',
    );
    File(p.join(cases.path, 'exists.yaml')).writeAsStringSync('''
id: exists
skill: optional-skill
routing: should_not_trigger
input: unrelated
rules:
  - kind: file_exists
    path: evals/cases/exists.yaml
''');
    final report = await evalAllSkills(p.join(root.path, 'skills'));
    final optional = report.results.singleWhere(
      (final r) => r.skillName == 'optional-skill',
    );
    expect(optional.total, 1);
    expect(optional.isOk, true);
  });
  test('oversized goal refuses before invoking the native action', () async {
    File(p.join(root.path, 'steward.yaml')).writeAsStringSync(
      validStewardV1().replaceFirst(
        'argv: [steward, doctor, --json]',
        'argv: [/bin/sh, -c, "touch native-was-invoked"]',
      ),
    );
    final result = await cli([
      'action',
      'run',
      'doctor.local',
      '--goal',
      'x' * 2049,
    ]);
    expect(result.exitCode, isNonZero);
    expect(File(p.join(root.path, 'native-was-invoked')).existsSync(), isFalse);
    expect(result.stderr, contains('2048'));
  });

  test('default CLI omits guidance and keeps the native status', () async {
    File(p.join(root.path, 'steward.yaml')).writeAsStringSync(
      validStewardV1().replaceFirst(
        'argv: [steward, doctor, --json]',
        'argv: [/bin/sh, -c, "exit 7"]',
      ),
    );
    final result = await cli(['action', 'run', 'doctor.local', '--json']);
    expect(result.exitCode, 7);
    final payload = jsonDecode(result.stdout as String) as Map;
    expect(payload['status'], 'failed');
    expect(payload, isNot(contains('guidance')));
    final advised = await cli([
      'action',
      'run',
      'doctor.local',
      '--json',
      '--guidance',
    ]);
    expect(advised.exitCode, result.exitCode);
    final withAdvice = jsonDecode(advised.stdout as String) as Map;
    expect(withAdvice.remove('guidance'), isA<Map>());
    expect(withAdvice['status'], payload['status']);
  });
}
