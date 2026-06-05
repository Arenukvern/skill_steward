import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Bundles local skills into a distribution manifest (skills.sh.json)
class BundleCommand extends Command<void> {
  @override
  final name = 'bundle';

  @override
  final description = 'Bundles local skills into a distribution manifest.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final config = await StewardConfig.load(root);

    if (config.skillsDistribution.isEmpty) {
      print('No skills_distribution configured in steward.yaml.');
      print('Add a block like:');
      print('skills_distribution:');
      print('  source_dir: "skills/"');
      print('  output: "skills.sh.json"');
      exit(1);
    }

    final sourceDirName =
        config.skillsDistribution['source_dir'] as String? ?? 'skills/';
    final outputName =
        config.skillsDistribution['output'] as String? ?? 'skills.sh.json';

    final sourceDir = Directory(p.join(root, sourceDirName));
    if (!sourceDir.existsSync()) {
      print('Error: Source directory ${sourceDir.path} does not exist.');
      exit(1);
    }

    final skills = <String>[];
    for (final entity in sourceDir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (!name.startsWith('.')) {
          skills.add(name);
        }
      }
    }

    skills.sort();

    final outMap = {'skills': skills};

    final outPath = p.join(root, outputName);
    final outFile = File(outPath);
    await outFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(outMap)}\n',
    );
    print('Successfully bundled ${skills.length} skills into $outputName.');

    // Universal Translation
    final instructions =
        'You are operating in a repository governed by Skill Steward.\nDo not run complex bash scripts manually. Use `steward mcp` or the underlying pipelines.\n\nAvailable Pipelines:\n${config.pipelines.keys
            .map((final k) {
              final p = config.pipelines[k];
              final desc = p is Map ? p['desc'] : '';
              return '- $k: $desc';
            })
            .join('\n')}\n\nAvailable Skills:\n${skills.map((final s) => '- $s').join('\n')}';

    // 1. Emit .clinerules
    final clineFile = File(p.join(root, '.clinerules'));
    await clineFile.writeAsString('$instructions\n');
    print('Generated .clinerules');

    // 2. Emit .cursor/rules/steward.mdc
    final cursorDir = Directory(p.join(root, '.cursor', 'rules'));
    if (!cursorDir.existsSync()) {
      cursorDir.createSync(recursive: true);
    }
    final cursorFile = File(p.join(cursorDir.path, 'steward.mdc'));
    final cursorContent =
        '---\ndescription: Global Steward Governance\nglobs: *\n---\n\n$instructions\n';
    await cursorFile.writeAsString(cursorContent);
    print('Generated .cursor/rules/steward.mdc');

    exit(0);
  }
}
