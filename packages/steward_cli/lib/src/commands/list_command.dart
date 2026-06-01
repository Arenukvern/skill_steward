import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/skill_frontmatter.dart';

/// Lists all installable skills with their descriptions.
///
/// Pure Dart port of scripts/list-skills.mjs.
/// No longer delegates to pnpm/npm.
class ListCommand extends Command<void> {
  @override
  final name = 'list';

  @override
  final description = 'List skills in skills/ with their descriptions.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final skillsDir = Directory(p.join(root, 'skills'));

    if (!skillsDir.existsSync()) {
      stderr.writeln('steward list: skills/ directory not found in $root');
      exit(1);
    }

    final entries =
        skillsDir
            .listSync()
            .whereType<Directory>()
            .where(
              (final d) =>
                  !p.basename(d.path).startsWith('_') &&
                  !p.basename(d.path).startsWith('.'),
            )
            .toList()
          ..sort(
            (final a, final b) =>
                p.basename(a.path).compareTo(p.basename(b.path)),
          );

    for (final dir in entries) {
      final skillName = p.basename(dir.path);
      final skillMd = File(p.join(dir.path, 'SKILL.md'));
      String description = '(missing SKILL.md)';

      if (skillMd.existsSync()) {
        final content = await skillMd.readAsString();
        final parsed = parseFrontmatter(content);
        final raw = parsed['description'] ?? '';
        description = raw.length > 80 ? raw.substring(0, 80) : raw;
      }

      stdout.writeln('$skillName\t$description');
    }
  }
}
