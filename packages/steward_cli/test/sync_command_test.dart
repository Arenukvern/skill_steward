import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/sync_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late Directory skillsDir;
  late StringBuffer out;

  setUp(() {
    exitCode = 0;
    tempDir = Directory.systemTemp.createTempSync('steward_sync_test_');
    skillsDir = Directory(p.join(tempDir.path, '.agents', 'skills'))
      ..createSync(recursive: true);
    File(p.join(tempDir.path, 'skills.sh.json')).writeAsStringSync(
      jsonEncode({
        'skills': ['repo-quality-system-lifecycle', 'skill-authoring-lifecycle'],
      }),
    );
    out = StringBuffer();
  });

  tearDown(() {
    exitCode = 0;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<Map<String, dynamic>> runSync([
    final List<String> extraArgs = const [],
  ]) async {
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SyncCommand(out, tempDir));
    await runner.run(['sync', '--json', ...extraArgs]);
    return jsonDecode(out.toString()) as Map<String, dynamic>;
  }

  Directory installSkill(
    final String name, {
    final String? author,
    final String skillDirRoot = '',
  }) {
    final dir = Directory(
      p.join(tempDir.path, skillDirRoot, '.agents', 'skills', name),
    )..createSync(recursive: true);
    final authorLine = author == null ? '' : '\nmetadata:\n  author: $author\n';
    File(
      p.join(dir.path, 'SKILL.md'),
    ).writeAsStringSync('---\nname: $name\n$authorLine---\n\n# $name\n');
    return dir;
  }

  test('report mode flags retired and author-owned stale skills without deleting', () async {
    installSkill('repo-quality-system-lifecycle');
    installSkill('mixture-of-experts');
    installSkill('docs-refresh');
    installSkill('gsap');
    installSkill('steward-dev-build', author: 'skill-steward');
    installSkill('other-plugin', author: 'someone-else');

    final payload = await runSync();

    expect(exitCode, 1);
    expect(payload['schema_version'], 'steward.sync.v1');
    expect(payload['prune'], isFalse);
    expect(payload['stale_total'], 2);
    final scopes = (payload['scopes'] as List).cast<Map<String, dynamic>>();
    final scope = scopes.single;
    expect(scope['kind'], 'project');
    final staleNames = [
      for (final entry in (scope['stale'] as List).cast<Map<String, dynamic>>())
        entry['name'],
    ]..sort();
    expect(staleNames, ['docs-refresh', 'mixture-of-experts']);
    expect(scope['unrecognized'], ['steward-dev-build']);
    expect(scope['foreign'], 2);
    expect(scope['missing'], ['skill-authoring-lifecycle']);
    expect(Directory(p.join(skillsDir.path, 'mixture-of-experts')).existsSync(), isTrue);
  });

  test('clean install exits 0 with nothing stale', () async {
    installSkill('repo-quality-system-lifecycle');
    installSkill('skill-authoring-lifecycle');
    installSkill('gsap');

    final payload = await runSync();

    expect(exitCode, 0);
    expect(payload['stale_total'], 0);
    final scopes = (payload['scopes'] as List).cast<Map<String, dynamic>>();
    expect(scopes.single['missing'], isEmpty);
    expect(scopes.single['foreign'], 1);
  });

  test('prune deletes stale entries and keeps manifest, foreign, and author-only skills', () async {
    final staleDir = installSkill('mixture-of-experts');
    final keptDir = installSkill('repo-quality-system-lifecycle');
    final foreignDir = installSkill('gsap');
    final authoredDir = installSkill('sibling-skill', author: 'skill-steward');

    final payload = await runSync(['--prune']);

    expect(exitCode, 0);
    expect(payload['pruned_total'], 1);
    expect(payload['failures'], isEmpty);
    expect(staleDir.existsSync(), isFalse);
    expect(keptDir.existsSync(), isTrue);
    expect(foreignDir.existsSync(), isTrue);
    expect(authoredDir.existsSync(), isTrue);
  });

  test('prune removes a retired symlink but keeps its target directory', () async {
    final target = Directory(p.join(tempDir.path, 'elsewhere', 'vision-alignment-foresight'))
      ..createSync(recursive: true);
    File(p.join(target.path, 'SKILL.md')).writeAsStringSync('# old\n');
    Link(
      p.join(skillsDir.path, 'vision-alignment-foresight'),
    ).createSync(target.path);

    final payload = await runSync(['--prune']);

    expect(exitCode, 0);
    expect(payload['pruned_total'], 1);
    expect(Link(p.join(skillsDir.path, 'vision-alignment-foresight')).existsSync(), isFalse);
    expect(target.existsSync(), isTrue);
  });

  test('explicit --path scopes are scanned and de-duplicated', () async {
    final extra = Directory(p.join(tempDir.path, 'extra-skills'))
      ..createSync();
    installSkill('mixture-of-experts');
    Directory(p.join(extra.path, 'skill-eval-improve')).createSync();

    final payload = await runSync(['--path', extra.path]);

    expect(exitCode, 1);
    final scopes = (payload['scopes'] as List).cast<Map<String, dynamic>>();
    expect(scopes.length, 2);
    final extraScope = scopes.firstWhere((final s) => s['kind'] == 'explicit');
    final extraStale = (extraScope['stale'] as List).cast<Map<String, dynamic>>();
    expect(extraStale.single['name'], 'skill-eval-improve');
  });

  test('global scope scans a base directory when provided', () async {
    final home = Directory(p.join(tempDir.path, 'home'))..createSync();
    Directory(p.join(home.path, '.codex', 'skills', 'skill-source-citations'))
        .createSync(recursive: true);
    installSkill('repo-quality-system-lifecycle');

    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SyncCommand(buffer, tempDir, home));
    await runner.run(['sync', '--json', '--global']);
    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;

    expect(exitCode, 1);
    final scopes = (payload['scopes'] as List).cast<Map<String, dynamic>>();
    final codexScope = scopes.firstWhere(
      (final s) =>
          s['kind'] == 'global' &&
          p.basename(p.dirname(s['path'] as String)) == '.codex',
    );
    final codexStale = (codexScope['stale'] as List).cast<Map<String, dynamic>>();
    expect(codexStale.single['name'], 'skill-source-citations');
  });

  test('missing skills.sh.json fails with usage exit code', () async {
    File(p.join(tempDir.path, 'skills.sh.json')).deleteSync();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SyncCommand(out, tempDir));

    await runner.run(['sync', '--json']);

    expect(exitCode, 64);
    expect(out.toString(), isEmpty);
  });

  test('retired-name entry without SKILL.md is still owned and pruned', () async {
    Directory(p.join(skillsDir.path, 'docs-refresh-lifecycle')).createSync();

    final payload = await runSync(['--prune']);

    expect(exitCode, 0);
    expect(payload['pruned_total'], 1);
  });
}
