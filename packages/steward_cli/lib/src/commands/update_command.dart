import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/skill_frontmatter.dart';
import 'install_command.dart';

class UpdateCommand extends Command<void> {
  UpdateCommand() {
    argParser
      ..addFlag(
        'local',
        abbr: 'l',
        help: 'Update skill repository-locally in .agents/skills/.',
        defaultsTo: true,
      )
      ..addOption(
        'target',
        abbr: 't',
        help: 'Compatibility profile (cursor | claude | generic).',
        allowed: ['cursor', 'claude', 'generic'],
        defaultsTo: 'generic',
      )
      ..addOption(
        'type',
        help: 'Filter skill updates by type (governance | developer).',
        allowed: ['governance', 'developer'],
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force overwrite local changes.',
      );
  }

  @override
  final name = 'update';

  @override
  final description =
      'Update local skills according to skills.json pinned sources.';

  @override
  Future<void> run() async {
    final isLocal = argResults!['local'] as bool;
    final target = argResults!['target'] as String;
    final typeFilter = argResults!['type'] as String?;
    final force = argResults!['force'] as bool;

    final root = findRepoRoot(Directory.current);
    final skillsJsonFile = File(p.join(root, 'skills.json'));

    if (!skillsJsonFile.existsSync()) {
      stderr.writeln(
        'No skills.json file found in project root. Run install command first.',
      );
      exit(1);
    }

    final raw = await skillsJsonFile.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final skillsArray = data['skills'] as List?;

    if (skillsArray == null || skillsArray.isEmpty) {
      stdout.writeln('skills.json contains no skills to update.');
      return;
    }

    stdout.writeln('Checking for updates...');

    for (final item in skillsArray) {
      if (item is Map<String, dynamic>) {
        final source = item['source'] as String?;
        final lockedCommit = item['commit'] as String?;
        final ref = item['ref'] as String? ?? 'main';
        final skills =
            (item['skills'] as List?)?.cast<String>() ?? const <String>[];

        if (source == null || source.isEmpty) continue;

        final repoUrl = source.startsWith('http')
            ? source
            : 'https://github.com/$source.git';

        // Use git ls-remote to query the latest commit hash of the remote branch/ref
        final lsRes = await Process.run('git', [
          'ls-remote',
          repoUrl,
          'refs/heads/$ref',
        ]);
        if (lsRes.exitCode != 0) {
          stderr.writeln('Failed to query remote for $source: ${lsRes.stderr}');
          continue;
        }

        final stdoutStr = (lsRes.stdout as String).trim();
        if (stdoutStr.isEmpty) {
          stderr.writeln('No ref found for branch "$ref" in $source.');
          continue;
        }

        final latestCommit = stdoutStr.split(RegExp(r'\s+')).first;

        if (latestCommit == lockedCommit) {
          stdout.writeln(
            '✓ $source is up to date (locked at ${lockedCommit?.substring(0, 7)}).',
          );
        } else {
          stdout.writeln(
            'Updating $source: ${lockedCommit?.substring(0, 7)} -> ${latestCommit.substring(0, 7)}...',
          );
          // Run the git clone and installation routine for the new commit
          await _installFromSource(
            source,
            latestCommit,
            skills,
            root,
            isLocal,
            target,
            typeFilter,
            force,
          );

          // Write updated commit back to skills.json
          item['commit'] = latestCommit;
        }
      }
    }

    // Write updated manifest back to file
    await skillsJsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    stdout.writeln('Update complete.');
  }

  Future<void> _installFromSource(
    final String source,
    final String commitSha,
    final List<String> skillNames,
    final String root,
    final bool isLocal,
    final String target,
    final String? typeFilter,
    final bool force,
  ) async {
    final repoUrl = source.startsWith('http')
        ? source
        : 'https://github.com/$source.git';
    final tempDir = Directory(p.join(root, '.steward_temp'));

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }

    final cloneRes = await Process.run('git', ['clone', repoUrl, tempDir.path]);
    if (cloneRes.exitCode != 0) {
      stderr.writeln(
        'Failed to clone repository during update: ${cloneRes.stderr}',
      );
      return;
    }

    // Checkout specific commit SHA
    final checkoutRes = await Process.run('git', [
      '-C',
      tempDir.path,
      'checkout',
      commitSha,
    ]);
    if (checkoutRes.exitCode != 0) {
      stderr.writeln(
        'Failed to checkout commit $commitSha: ${checkoutRes.stderr}',
      );
      await tempDir.delete(recursive: true);
      return;
    }

    try {
      final List<String> targetsToInstall = [];
      if (skillNames.isEmpty) {
        final searchDir = Directory(p.join(tempDir.path, 'skills'));
        final dirToSearch = searchDir.existsSync() ? searchDir : tempDir;
        final list = await dirToSearch.list().toList();
        for (final entry in list) {
          if (entry is Directory) {
            final name = p.basename(entry.path);
            if (!name.startsWith('.') &&
                File(p.join(entry.path, 'SKILL.md')).existsSync()) {
              targetsToInstall.add(name);
            }
          }
        }
      } else {
        targetsToInstall.addAll(skillNames);
      }

      for (final skillName in targetsToInstall) {
        Directory? srcDir;
        for (final loc in [
          p.join(tempDir.path, 'skills', skillName),
          p.join(tempDir.path, skillName),
          tempDir.path,
        ]) {
          final dir = Directory(loc);
          if (dir.existsSync() &&
              File(p.join(dir.path, 'SKILL.md')).existsSync()) {
            srcDir = dir;
            break;
          }
        }

        if (srcDir == null) {
          stderr.writeln('Could not find skill "$skillName" in updated repo.');
          continue;
        }

        final destDir = _getDestDir(root, isLocal, skillName);
        await _copySkillDirectory(srcDir, destDir, target, typeFilter, force);
      }
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Directory _getDestDir(
    final String root,
    final bool isLocal,
    final String skillName,
  ) {
    if (isLocal) {
      return Directory(p.join(root, '.agents', 'skills', skillName));
    }
    return Directory(p.join(root, 'skills', skillName));
  }

  Future<bool> _copySkillDirectory(
    final Directory src,
    final Directory dest,
    final String target,
    final String? typeFilter,
    final bool force,
  ) async {
    final skillMdFile = File(p.join(src.path, 'SKILL.md'));
    if (skillMdFile.existsSync() && typeFilter != null) {
      final content = await skillMdFile.readAsString();
      final parsed = parseFrontmatter(content);
      final skillType = parsed['type'];
      if (skillType != typeFilter) {
        stdout.writeln(
          'Skipping skill "${p.basename(src.path)}" (type "$skillType" != filter "$typeFilter").',
        );
        return false;
      }
    }

    if (dest.existsSync() && !force) {
      stdout.writeln(
        'Local modifications may exist at ${dest.path}. Use --force to overwrite.',
      );
      return false;
    }
    if (dest.existsSync()) {
      await dest.delete(recursive: true);
    }
    await dest.create(recursive: true);

    await _copyDirectory(src, dest);

    if (skillMdFile.existsSync()) {
      final content = await skillMdFile.readAsString();
      final translated = InstallCommand.translateFrontmatter(content, target);
      final finalSkillMdFile = File(p.join(dest.path, 'SKILL.md'));
      await finalSkillMdFile.writeAsString(translated);
    }

    stdout.writeln('Successfully updated skill at ${dest.path}');
    return true;
  }

  Future<void> _copyDirectory(final Directory src, final Directory dest) async {
    final entries = await src.list().toList();
    for (final entry in entries) {
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;

      if (entry is Directory) {
        final newDest = Directory(p.join(dest.path, name));
        await newDest.create();
        await _copyDirectory(entry, newDest);
      } else if (entry is File) {
        final newDestFile = File(p.join(dest.path, name));
        await entry.copy(newDestFile.path);
      }
    }
  }
}
