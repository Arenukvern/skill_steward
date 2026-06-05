import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/skill_frontmatter.dart';
import '../validation/validation.dart' show StewardConfig;

/// Scans the workspace and outputs an operational map for agents.
class MapCommand extends Command<void> {
  MapCommand([this.outputSink]);

  final StringSink? outputSink;

  @override
  final name = 'map';

  @override
  final description =
      'Print a Markdown map of active skills, task runners, and docs for agents.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final config = await StewardConfig.load(root);
    final buffer = StringBuffer();

    final harnessName = config.harnessName ?? 'Skill Steward';
    buffer.writeln('# 🧭 $harnessName Agent Map');
    buffer.writeln();

    // 1. Task Runner & Commands detection
    buffer.writeln('## 🛠️ Detected Task Runner & Pipelines');
    buffer.writeln();
    final taskConfigs = <String>[];
    String preferredRunner = '';
    String runCmd = '';

    if (File(p.join(root, 'Justfile')).existsSync() ||
        File(p.join(root, 'justfile')).existsSync()) {
      taskConfigs.add('Justfile');
      preferredRunner = 'just';
      runCmd = 'just <task>';
    } else if (File(p.join(root, 'Makefile')).existsSync() ||
        File(p.join(root, 'makefile')).existsSync()) {
      taskConfigs.add('Makefile');
      preferredRunner = 'make';
      runCmd = 'make <target>';
    } else if (File(p.join(root, 'package.json')).existsSync()) {
      taskConfigs.add('package.json (Node)');
      preferredRunner = 'pnpm/npm';
      runCmd = 'pnpm run <script>';
    } else if (File(p.join(root, 'pubspec.yaml')).existsSync()) {
      taskConfigs.add('pubspec.yaml (Dart)');
      preferredRunner = 'dart';
      runCmd = 'dart run :<target>';
    }

    if (config.preferredRunner != null && config.preferredRunner!.isNotEmpty) {
      preferredRunner = config.preferredRunner!;
      runCmd = '$preferredRunner <task>';
      if (!taskConfigs.contains(preferredRunner)) {
        taskConfigs.add(preferredRunner);
      }
    }

    if (taskConfigs.isNotEmpty) {
      buffer.writeln('- **Configs detected:** ${taskConfigs.join(", ")}');
      buffer.writeln(
        '- **Preferred Runner:** `$preferredRunner` (Run: `$runCmd`)',
      );

      // Suggest standard tasks
      buffer.writeln('- **Standard Pipelines:**');
      if (config.pipelines.isNotEmpty) {
        config.pipelines.forEach((final key, final val) {
          String cmd = '';
          String desc = '';
          if (val is String) {
            cmd = val;
          } else if (val is Map) {
            cmd = val['cmd'] as String? ?? '';
            desc = val['desc'] as String? ?? '';
          }
          if (cmd.isNotEmpty) {
            final descStr = desc.isNotEmpty ? ' : $desc' : '';
            buffer.writeln('  - `$key` (Run: `$cmd`)$descStr');
          }
        });
      } else {
        buffer.writeln('  - `validate` : Check skills and repository hygiene');
        buffer.writeln('  - `test`     : Run test/evaluation suite');
      }
    } else {
      buffer.writeln('_No standard task runner config found in project root._');
    }
    buffer.writeln();

    // Archetype detection
    buffer.writeln('## 🧭 Repository Archetype');
    buffer.writeln();
    String archetype = 'B — Platform libs'; // Default or fallback
    String details = '';

    if (File(p.join(root, 'plugin', 'mcp.json')).existsSync() ||
        File(p.join(root, 'mcp.json')).existsSync()) {
      archetype = 'A — Product MCP';
      details =
          'This is a toolkit + MCP server repository. It implements agent capabilities and registers them in `plugin/mcp.json`.';
    } else if (File(p.join(root, 'skills.sh.json')).existsSync()) {
      try {
        final content = File(p.join(root, 'skills.sh.json')).readAsStringSync();
        if (content.contains(
              'https://skills.sh/schemas/skills.sh.schema.json',
            ) ||
            content.contains('skill_steward')) {
          archetype = 'E — Meta steward';
          details =
              'This is a meta-repository for agent skills and validation. It maintains governance guidelines and the `steward` CLI tool.';
        }
      } catch (_) {}
    }

    if (archetype == 'B — Platform libs') {
      final packagesDir = Directory(p.join(root, 'packages'));
      final toolDir = Directory(p.join(root, 'tool'));
      if (packagesDir.existsSync() &&
          (File(p.join(root, 'pubspec.yaml')).existsSync() ||
              File(p.join(root, 'package.json')).existsSync())) {
        archetype = 'B — Platform libs';
        details =
            'This is a platform library workspace containing modular packages/adapters. Central logic lives in core packages, mapped to transport/surface adapters.';
      } else if (toolDir.existsSync()) {
        archetype = 'C — CLI harness';
        details =
            'This is a CLI-first harness workspace. It provides command-line interfaces for agents or test runners without hosting public MCP APIs directly.';
      } else {
        details = 'Platform / general codebase workspace.';
      }
    }

    if (config.archetype != null && config.archetype!.isNotEmpty) {
      archetype = config.archetype!;
      if (archetype.startsWith('A')) {
        details =
            'This is a toolkit + MCP server repository. It implements agent capabilities and registers them in `plugin/mcp.json` or equivalent.';
      } else if (archetype.startsWith('B')) {
        details =
            'This is a platform library workspace containing modular packages/adapters. Central logic lives in core packages, mapped to transport/surface adapters.';
      } else if (archetype.startsWith('C')) {
        details =
            'This is a CLI-first harness workspace. It provides command-line interfaces for agents or test runners without hosting public MCP APIs directly.';
      } else if (archetype.startsWith('E')) {
        details =
            'This is a meta-repository for agent skills and validation. It maintains governance guidelines and the `steward` CLI tool.';
      } else {
        details = 'Configured repository archetype.';
      }
    }

    buffer.writeln('- **Detected Archetype:** `$archetype`');
    buffer.writeln('- **Role:** $details');
    buffer.writeln();

    // 2. Active Local Skills
    buffer.writeln('## 📚 Active Installed Skills');
    buffer.writeln();
    final skillsDir = Directory(p.join(root, '.agents', 'skills'));
    final List<Directory> localSkills = [];

    if (skillsDir.existsSync()) {
      try {
        final entries = skillsDir.listSync().whereType<Directory>();
        for (final entry in entries) {
          final name = p.basename(entry.path);
          if (!name.startsWith('.') &&
              File(p.join(entry.path, 'SKILL.md')).existsSync()) {
            localSkills.add(entry);
          }
        }
      } catch (_) {}
    }

    if (localSkills.isNotEmpty) {
      localSkills.sort(
        (final a, final b) => p.basename(a.path).compareTo(p.basename(b.path)),
      );
      buffer.writeln('| Skill | Type | Description | Path |');
      buffer.writeln('|---|---|---|---|');
      for (final dir in localSkills) {
        final name = p.basename(dir.path);
        final skillMd = File(p.join(dir.path, 'SKILL.md'));
        String desc = '';
        String type = 'developer';

        try {
          final content = await skillMd.readAsString();
          final parsed = parseFrontmatter(content);
          desc = parsed['description'] ?? '';
          if (desc.length > 60) {
            desc = '${desc.substring(0, 57)}...';
          }
          type = parsed['type'] ?? 'developer';
        } catch (_) {}

        buffer.writeln(
          '| `$name` | `$type` | $desc | `.agents/skills/$name/` |',
        );
      }
    } else {
      buffer.writeln(
        '_No skills installed. Run `steward install` to add skills._',
      );
    }
    buffer.writeln();

    // 2a. Recommended Skills to Adopt
    buffer.writeln('## 💡 Recommended Skills to Adopt');
    buffer.writeln(
      'These base skills are recommended for installation to guide agents and maintain repository hygiene:',
    );
    buffer.writeln();

    final installedNames = localSkills.map((final d) => p.basename(d.path)).toSet();
    final recs = <Map<String, String>>[];

    if (!installedNames.contains('north-star-governance')) {
      recs.add({
        'name': 'north-star-governance',
        'why':
            'Governs plan hygiene, AGENTS.md routing maps, and docs.page structure. Essential for maintaining repository hygiene.',
      });
    }
    if (!installedNames.contains('adr-records')) {
      recs.add({
        'name': 'adr-records',
        'why':
            'Provides templates for Architectural Decision Records (ADRs). Highly recommended to record design choices and keep them auditable.',
      });
    }
    if (!installedNames.contains('faq-driven-docs')) {
      recs.add({
        'name': 'faq-driven-docs',
        'why':
            'Governs repo-level DESIGN_FAQ (why) and DX_FAQ (how) files, separating architectural reasons from operational guidelines.',
      });
    }
    if (!installedNames.contains('north-star-governance')) {
      recs.add({
        'name': 'north-star-governance',
        'why':
            'Helps connect folder-level READMEs and guides into a cohesive documentation lattice for incoming agents.',
      });
    }
    if (!installedNames.contains('mcp-harness-repo-maintainer')) {
      recs.add({
        'name': 'mcp-harness-repo-maintainer',
        'why':
            'Establishes task runners and automated validation gates. Highly useful for standardizing testing pipelines.',
      });
    }
    if (!installedNames.contains('mcp-harness-repo-maintainer') &&
        (archetype.contains('Product MCP') ||
            archetype.contains('Meta steward'))) {
      recs.add({
        'name': 'mcp-harness-repo-maintainer',
        'why':
            'Tailored for MCP servers; manages JSON schema registry sync, contract checking, and release packaging.',
      });
    }

    if (recs.isNotEmpty) {
      buffer.writeln('| Skill | Why it is useful / when to adopt |');
      buffer.writeln('|---|---|');
      for (final rec in recs) {
        buffer.writeln('| `${rec['name']}` | ${rec['why']} |');
      }
    } else {
      buffer.writeln(
        '✓ Excellent: All recommended base skills are currently installed.',
      );
    }
    buffer.writeln();

    // 2b. Exported Repository Skills (locally defined under skills/)
    final repoSkillsDir = Directory(p.join(root, 'skills'));
    final List<Directory> exportedSkills = [];
    if (repoSkillsDir.existsSync() && repoSkillsDir.path != skillsDir.path) {
      try {
        final entries = repoSkillsDir.listSync().whereType<Directory>();
        for (final entry in entries) {
          final name = p.basename(entry.path);
          if (!name.startsWith('.') &&
              File(p.join(entry.path, 'SKILL.md')).existsSync()) {
            exportedSkills.add(entry);
          }
        }
      } catch (_) {}
    }

    if (exportedSkills.isNotEmpty) {
      buffer.writeln('## 📦 Exported Repository Skills');
      buffer.writeln(
        'These are custom agent skills authored in this repository to assist developers/agents:',
      );
      buffer.writeln();
      exportedSkills.sort(
        (final a, final b) => p.basename(a.path).compareTo(p.basename(b.path)),
      );
      buffer.writeln('| Skill | Type | Description | Path |');
      buffer.writeln('|---|---|---|---|');
      for (final dir in exportedSkills) {
        final name = p.basename(dir.path);
        final skillMd = File(p.join(dir.path, 'SKILL.md'));
        String desc = '';
        String type = 'developer';

        try {
          final content = await skillMd.readAsString();
          final parsed = parseFrontmatter(content);
          desc = parsed['description'] ?? '';
          if (desc.length > 60) {
            desc = '${desc.substring(0, 57)}...';
          }
          type = parsed['type'] ?? 'developer';
        } catch (_) {}

        buffer.writeln('| `$name` | `$type` | $desc | `skills/$name/` |');
      }
      buffer.writeln();
    }

    // 3. Documentation Lattice
    buffer.writeln('## 🧭 Documentation Lattice');
    buffer.writeln();
    final docFiles = <String, String>{};

    for (final relPath in [
      'steward.yaml',
      'steward.yml',
      'steward.json',
      'docs/NORTH_STAR.mdx',
      'NORTH_STAR.mdx',
      'NORTH_STAR.md',
      'docs/DESIGN_FAQ.mdx',
      'docs/DX_FAQ.mdx',
      'docs/decisions/README.mdx',
      'docs/decisions/README.md',
    ]) {
      if (File(p.join(root, relPath)).existsSync()) {
        final name = p.basename(relPath);
        docFiles[name] = relPath;
      }
    }

    if (config.docs.isNotEmpty) {
      config.docs.forEach((final name, final relPath) {
        if (File(p.join(root, relPath)).existsSync() ||
            Directory(p.join(root, relPath)).existsSync()) {
          docFiles[name] = relPath;
        }
      });
    }

    if (docFiles.isNotEmpty) {
      docFiles.forEach((final name, final path) {
        buffer.writeln('- **$name**: [`$path`]($path)');
      });
    } else {
      buffer.writeln('_No core documentation guides detected._');
    }
    buffer.writeln();

    // 4. Plan Hygiene (unmerged plans warning)
    final activePlans = <String>[];
    final taskFile = File(p.join(root, 'task.md'));
    if (taskFile.existsSync()) activePlans.add('task.md');

    final planFile = File(p.join(root, 'implementation_plan.md'));
    if (planFile.existsSync()) activePlans.add('implementation_plan.md');

    final activePlansDir = Directory(
      p.join(root, 'docs', 'exec-plans', 'active'),
    );
    if (activePlansDir.existsSync()) {
      try {
        final planFiles = activePlansDir.listSync().whereType<File>();
        for (final f in planFiles) {
          final name = p.basename(f.path);
          if (!name.startsWith('.')) {
            activePlans.add('docs/exec-plans/active/$name');
          }
        }
      } catch (_) {}
    }

    if (activePlans.isNotEmpty) {
      buffer.writeln('## ⚠️ Active Plan Hygiene Alerts');
      buffer.writeln();
      buffer.writeln('> [!WARNING]');
      buffer.writeln(
        '> Stale/active plan files are present in the workspace. Clean these up before merging:',
      );
      for (final plan in activePlans) {
        buffer.writeln('> - `$plan`');
      }
    } else {
      buffer.writeln('## ✅ Plan Hygiene Status');
      buffer.writeln();
      buffer.writeln(
        '✓ Clean: No active or stale plan files detected in the workspace.',
      );
    }
    buffer.writeln();

    final sink = outputSink ?? stdout;
    sink.write(buffer.toString());
  }
}
