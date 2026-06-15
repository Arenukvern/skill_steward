import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../path_safety.dart';
import '../repo_root.dart';
import '../skill_source.dart';
import '../validation/skill_frontmatter.dart';

class InstallCommand extends Command<void> {
  InstallCommand() {
    argParser
      ..addFlag(
        'local',
        abbr: 'l',
        help: 'Install skill repository-locally in .agents/skills/.',
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
        help: 'Filter skill installation by type (governance | developer).',
        allowed: ['governance', 'developer'],
      )
      ..addFlag(
        'lock',
        help: 'Lock/pin the commit hash in skills.json.',
        defaultsTo: true,
      )
      ..addFlag(
        'allow-local-source',
        help:
            'Allow maintainer-only local path or file:// skill sources. Disabled by default for consumer installs.',
      )
      ..addFlag('force', abbr: 'f', help: 'Overwrite existing local skills.')
      ..addFlag(
        'json',
        help:
            'Output structured diagnostic JSON instead of human-readable text.',
      );
  }

  @override
  final name = 'install';

  @override
  final description = 'Install skills into the project workspace.';

  @override
  Future<void> run() async {
    final isLocal = argResults!['local'] as bool;
    final target = argResults!['target'] as String;
    final typeFilter = argResults!['type'] as String?;
    final lock = argResults!['lock'] as bool;
    final force = argResults!['force'] as bool;
    final allowLocalSource = argResults!['allow-local-source'] as bool;

    final root = findRepoRoot(Directory.current);

    if (argResults!.rest.isEmpty) {
      // 1. Install all skills from local skills.json
      final skillsJsonFile = File(p.join(root, 'skills.json'));
      if (!skillsJsonFile.existsSync()) {
        throw Exception(
          'No skill specified and no skills.json found in project root.',
        );
      }

      await _installFromConfig(
        skillsJsonFile,
        root,
        isLocal,
        target,
        typeFilter,
        lock,
        force,
        allowLocalSource,
      );
    } else {
      // 2. Install a specific skill
      final arg = argResults!.rest.first;
      await _installSpecific(
        arg,
        root,
        isLocal,
        target,
        typeFilter,
        lock,
        force,
        allowLocalSource,
      );
    }
  }

  Future<void> _installFromConfig(
    final File configFile,
    final String root,
    final bool isLocal,
    final String target,
    final String? typeFilter,
    final bool lock,
    final bool force,
    final bool allowLocalSource,
  ) async {
    final raw = await configFile.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final skillsArray = data['skills'] as List?;

    if (skillsArray == null || skillsArray.isEmpty) {
      stdout.writeln('skills.json contains no skills to install.');
      return;
    }

    for (final item in skillsArray) {
      if (item is Map<String, dynamic>) {
        final source = item['source'] as String?;
        final commit = item['commit'] as String?;
        final ref = item['ref'] as String?;
        final skills =
            (item['skills'] as List?)?.cast<String>() ?? const <String>[];

        if (source == null || source.isEmpty) continue;

        if (skills.isEmpty) {
          stdout.writeln(
            'No specific skills listed for source "$source". Installing all.',
          );
        }

        // We can pass commit/ref as pin if present
        final pin = commit ?? ref;
        await _installFromSource(
          source,
          skills,
          pin,
          root,
          isLocal,
          target,
          typeFilter,
          lock,
          force,
          allowLocalSource,
        );
      }
    }
  }

  Future<void> _installSpecific(
    final String arg,
    final String root,
    final bool isLocal,
    final String target,
    final String? typeFilter,
    final bool lock,
    final bool force,
    final bool allowLocalSource,
  ) async {
    // Expected formats:
    // - local path: e.g. "skills/repository-governance-lifecycle"
    // - repo/skill: e.g. "Arenukvern/skill_steward/repository-governance-lifecycle"
    // - repo only (installs all): e.g. "Arenukvern/skill_steward"

    if (_isExplicitSource(arg)) {
      await _installFromSource(
        arg,
        const <String>[],
        null,
        root,
        isLocal,
        target,
        typeFilter,
        lock,
        force,
        allowLocalSource,
      );
      return;
    }

    if (Directory(arg).existsSync()) {
      // Local directory copy
      if (!allowLocalSource) {
        throw ArgumentError(
          'Local skill source "$arg" requires --allow-local-source. Local sources are maintainer-only development paths, not consumer defaults.',
        );
      }
      final skillName = p.basename(arg);
      validateSkillName(skillName);
      final destDir = _getDestDir(root, isLocal, skillName);
      await _copySkillDirectory(
        Directory(Directory(arg).resolveSymbolicLinksSync()),
        destDir,
        target,
        typeFilter,
        force,
      );
      return;
    }

    final parts = arg.split('/');
    if (parts.length >= 2) {
      final owner = parts[0];
      final repo = parts[1];
      final source = '$owner/$repo';
      final skills = parts.length > 2
          ? [parts.sublist(2).join('/')]
          : <String>[];
      validateSkillNames(skills);
      await _installFromSource(
        source,
        skills,
        null,
        root,
        isLocal,
        target,
        typeFilter,
        lock,
        force,
        allowLocalSource,
      );
    } else {
      throw Exception(
        'Invalid install target: $arg. Use local path or repo format (owner/repo/skill).',
      );
    }
  }

  bool _isExplicitSource(final String arg) =>
      arg.startsWith('http://') ||
      arg.startsWith('https://') ||
      arg.startsWith('ssh://') ||
      arg.startsWith('git@') ||
      arg.startsWith('file://');

  Future<void> _installFromSource(
    final String source,
    final List<String> skillNames,
    final String? pin,
    final String root,
    final bool isLocal,
    final String target,
    final String? typeFilter,
    final bool lock,
    final bool force,
    final bool allowLocalSource,
  ) async {
    validateSkillNames(skillNames);
    final skillSource = resolveSkillSource(
      source,
      root,
      allowLocalSource: allowLocalSource,
    );
    stdout.writeln('Cloning ${skillSource.description}...');

    final tempDir = Directory(p.join(root, '.steward_temp'));
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }

    final trimmedPin = pin?.trim();
    final commitPin =
        trimmedPin != null &&
        RegExp(r'^[0-9a-fA-F]{7,40}$').hasMatch(trimmedPin);
    final cloneArgs = ['clone'];
    if (trimmedPin == null || trimmedPin.isEmpty) {
      cloneArgs.addAll(['--depth', '1']);
    } else if (!commitPin) {
      cloneArgs.addAll(['--depth', '1', '--branch', trimmedPin]);
    }
    cloneArgs.addAll([skillSource.cloneTarget, tempDir.path]);

    final cloneRes = await Process.run('git', cloneArgs);
    if (cloneRes.exitCode != 0) {
      throw Exception('Failed to clone repository: ${cloneRes.stderr}');
    }

    if (commitPin) {
      final checkoutRes = await Process.run('git', [
        '-C',
        tempDir.path,
        'checkout',
        '--detach',
        trimmedPin,
      ]);
      if (checkoutRes.exitCode != 0) {
        throw Exception(
          'Failed to checkout commit $trimmedPin: ${checkoutRes.stderr}',
        );
      }
    }

    // Get the actual commit SHA for lock pinning
    final revRes = await Process.run('git', [
      '-C',
      tempDir.path,
      'rev-parse',
      'HEAD',
    ]);
    final commitSha = revRes.exitCode == 0
        ? (revRes.stdout as String).trim()
        : null;

    try {
      final List<String> targetsToInstall = [];
      if (skillNames.isEmpty) {
        // Find all skill folders under /skills or root
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
        if (targetsToInstall.isEmpty &&
            File(p.join(tempDir.path, 'SKILL.md')).existsSync()) {
          targetsToInstall.add(
            p.basename(skillSource.cloneTarget).replaceAll('.git', ''),
          );
        }
      } else {
        targetsToInstall.addAll(skillNames);
      }
      validateSkillNames(targetsToInstall);

      final List<String> successfullyInstalled = [];
      for (final skillName in targetsToInstall) {
        // Resolve skill source dir inside temp clone
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
          throw Exception(
            'Could not find skill "$skillName" in cloned repository.',
          );
        }

        final destDir = _getDestDir(root, isLocal, skillName);
        final success = await _copySkillDirectory(
          srcDir,
          destDir,
          target,
          typeFilter,
          force,
        );
        if (success) {
          successfullyInstalled.add(skillName);
        }
      }

      if (lock && commitSha != null && successfullyInstalled.isNotEmpty) {
        await _updateSkillsJsonLock(
          root,
          source,
          commitSha,
          successfullyInstalled,
        );
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
    validateSkillName(skillName);
    if (isLocal) {
      return Directory(
        resolveUnderRoot(root, p.join('.agents', 'skills', skillName)),
      );
    }
    return Directory(resolveUnderRoot(root, p.join('skills', skillName)));
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

    if (dest.existsSync()) {
      if (!force) {
        stdout.writeln(
          'Skill already exists at ${dest.path}. Use --force to overwrite.',
        );
        return false;
      }
      await dest.delete(recursive: true);
    }
    await dest.create(recursive: true);

    // Recursively copy directories & files
    await _copyDirectory(src, dest);

    // Profile translation on the output SKILL.md
    if (skillMdFile.existsSync()) {
      final content = await skillMdFile.readAsString();
      final translated = translateFrontmatter(content, target);
      final finalSkillMdFile = File(p.join(dest.path, 'SKILL.md'));
      await finalSkillMdFile.writeAsString(translated);
    }

    stdout.writeln('Successfully installed skill to ${dest.path}');
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

  static String translateFrontmatter(
    final String content,
    final String target,
  ) {
    if (target == 'generic') return content;

    // Lightweight frontmatter extraction and parsing
    final match = RegExp(r'^---\r?\n([\s\S]*?)\r?\n---').firstMatch(content);
    if (match == null) return content;

    final rawYaml = match.group(1)!;
    final body = content.substring(match.end);

    // If target is cursor, look for metadata -> cursor -> paths mapping to lift to top-level
    if (target == 'cursor') {
      // Find metadata: block
      final metadataIdx = rawYaml.indexOf('metadata:');
      if (metadataIdx != -1) {
        // We look for nested cursor block & paths:
        final cursorMatch = RegExp(
          r'^\s+cursor:\r?\n\s+paths:\r?\n((?:\s+-\s+.*(?:\r?\n)?)+)',
          multiLine: true,
        ).firstMatch(rawYaml.substring(metadataIdx));

        if (cursorMatch != null) {
          final pathsLines = cursorMatch.group(1)!;
          // Re-indent paths to top-level
          final topLevelPaths = pathsLines
              .split(RegExp(r'\r?\n'))
              .map((final line) => line.trim())
              .where((final line) => line.isNotEmpty)
              .map((final line) => '  $line')
              .join('\n');

          final newFrontmatter = 'paths:\n$topLevelPaths\n$rawYaml';
          return '---\n$newFrontmatter\n---$body';
        }
      }
    }

    return content;
  }

  Future<void> _updateSkillsJsonLock(
    final String root,
    final String source,
    final String commitSha,
    final List<String> installedSkills,
  ) async {
    final file = File(p.join(root, 'skills.json'));
    Map<String, dynamic> data = {'skills': []};

    if (file.existsSync()) {
      try {
        final raw = await file.readAsString();
        data = jsonDecode(raw) as Map<String, dynamic>;
      } on Object catch (_) {}
    }

    final skillsArray = (data['skills'] as List?) ?? [];
    bool found = false;

    for (int i = 0; i < skillsArray.length; i++) {
      final item = skillsArray[i];
      if (item is Map<String, dynamic> && item['source'] == source) {
        // Update existing source block
        item['commit'] = commitSha;
        final list = (item['skills'] as List?)?.cast<String>() ?? [];
        for (final s in installedSkills) {
          if (!list.contains(s)) {
            list.add(s);
          }
        }
        item['skills'] = list;
        found = true;
        break;
      }
    }

    if (!found) {
      skillsArray.add({
        'source': source,
        'commit': commitSha,
        'skills': installedSkills,
      });
    }

    data['skills'] = skillsArray;
    if (data[r'$schema'] == null) {
      data[r'$schema'] = 'https://unpkg.com/skillman/skills_schema.json';
    }

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln(
      'Updated skills.json with locked commit: ${commitSha.substring(0, 7)}',
    );
  }
}
