import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/skill_frontmatter.dart';

/// Lists all installable skills (maintainer mode) or locally installed skills (consumer mode).
class ListCommand extends Command<void> {
  @override
  final name = 'list';

  @override
  final description = 'List available or installed skills with their descriptions.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final isCoreRepo = File(p.join(root, 'skills.sh.json')).existsSync();

    if (isCoreRepo) {
      // 1. Maintainer Mode: list skills/ directory
      final skillsDir = Directory(p.join(root, 'skills'));

      if (!skillsDir.existsSync()) {
        stderr.writeln('steward list: skills/ directory not found in $root');
        exit(1);
      }

      final entries = skillsDir
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
    } else {
      // 2. Consumer Mode: list local skills in .agents/skills
      final localSkillsDir = Directory(p.join(root, '.agents', 'skills'));
      if (!localSkillsDir.existsSync()) {
        stdout.writeln('No skills installed under .agents/skills/ in this project.');
        return;
      }

      final entries = localSkillsDir
          .listSync()
          .whereType<Directory>()
          .where((final d) => !p.basename(d.path).startsWith('.'))
          .toList()
        ..sort((final a, final b) => p.basename(a.path).compareTo(p.basename(b.path)));

      if (entries.isEmpty) {
        stdout.writeln('No skills installed under .agents/skills/ in this project.');
        return;
      }

      stdout.writeln('Local skills installed in this project:');
      stdout.writeln();

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
}
