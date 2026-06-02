import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';

/// Cleanly removes a local skill and updates the manifest.
class UninstallCommand extends Command<void> {
  @override
  final name = 'uninstall';

  @override
  final description = 'Uninstall a local skill from the project and config.';

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Error: Please specify the name of the skill to uninstall.');
      exit(1);
    }

    final skillName = argResults!.rest.first;
    final root = findRepoRoot(Directory.current);

    // 1. Delete the local skill folder
    final localSkillDir = Directory(p.join(root, '.agents', 'skills', skillName));
    bool deletedAny = false;

    if (localSkillDir.existsSync()) {
      await localSkillDir.delete(recursive: true);
      stdout.writeln('Deleted skill folder: .agents/skills/$skillName');
      deletedAny = true;
    } else {
      stdout.writeln('Skill folder not found at .agents/skills/$skillName');
    }

    // 2. Clean up skills.json
    final skillsJsonFile = File(p.join(root, 'skills.json'));
    if (skillsJsonFile.existsSync()) {
      try {
        final raw = await skillsJsonFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
        final skillsArray = data['skills'] as List?;

        if (skillsArray != null) {
          bool manifestModified = false;
          final updatedSkillsArray = <Map<String, dynamic>>[];

          for (final item in skillsArray) {
            if (item is Map<String, dynamic>) {
              final list = (item['skills'] as List?)?.cast<String>() ?? [];
              if (list.contains(skillName)) {
                list.remove(skillName);
                item['skills'] = list;
                manifestModified = true;
              }
              // Only keep the source block if it still has skills or if it is the only way
              if (list.isNotEmpty) {
                updatedSkillsArray.add(item);
              } else {
                manifestModified = true; // removed empty source block
              }
            }
          }

          if (manifestModified) {
            data['skills'] = updatedSkillsArray;
            await skillsJsonFile.writeAsString(
              const JsonEncoder.withIndent('  ').convert(data),
            );
            stdout.writeln('Removed skill "$skillName" from skills.json');
            deletedAny = true;
          }
        }
      } catch (e) {
        stderr.writeln('Warning: Failed to update skills.json: $e');
      }
    }

    if (deletedAny) {
      stdout.writeln('Successfully uninstalled skill "$skillName".');
    } else {
      stdout.writeln('Skill "$skillName" was not found in the workspace.');
    }
  }
}
