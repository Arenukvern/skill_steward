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
    void write([final Object? object = '']) => buffer.writeln(object);

    final harnessName = config.harnessName ?? 'Skill Steward';
    write('# 🧭 $harnessName Agent Map');
    write();

    // 1. Task Runner & Commands detection
    write('## 🛠️ Detected Task Runner & Pipelines');
    write();
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
      write('- **Configs detected:** ${taskConfigs.join(", ")}');
      write('- **Preferred Runner:** `$preferredRunner` (Run: `$runCmd`)');

      if (config.isV1) {
        write('- **Typed Steward Actions:**');
        if (config.typedActions.isEmpty) {
          write(
            '  - none declared; run `steward doctor --json` to inspect adoption state',
          );
        } else {
          for (final action in config.typedActions) {
            write(
              '  - `${action.id}` '
              '(${action.safetyClass}/${action.defaultPolicy}) : '
              '${action.desc}',
            );
          }
        }
        if (config.probes.isNotEmpty) {
          write('- **Typed Probes:**');
          for (final entry in config.probes.entries) {
            final probe = entry.value;
            if (probe is Map) {
              final actions = probe['actions'] as List? ?? const [];
              write(
                '  - `${entry.key}` : ${actions.map((final e) => '`$e`').join(", ")}',
              );
            }
          }
        }
      } else if (config.pipelines.isNotEmpty) {
        write('- **Legacy Pipelines:**');
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
            write('  - `$key` (Run: `$cmd`)$descStr');
          }
        });
      } else {
        write('- **Standard Pipelines:**');
        write('  - `validate` : Check skills and repository hygiene');
        write('  - `test`     : Run test/evaluation suite');
      }
    } else {
      write('_No standard task runner config found in project root._');
    }
    write();

    // Archetype detection
    write('## 🧭 Repository Archetype');
    write();
    String archetype = 'library';
    String details = '';
    String archetypeSource = 'inferred from repository files';
    String archetypeConfidence = 'low';

    if (File(p.join(root, 'plugin', 'mcp.json')).existsSync() ||
        File(p.join(root, 'mcp.json')).existsSync()) {
      archetype = 'plugin';
      archetypeConfidence = 'medium';
      details =
          'This repository exposes host integration metadata or agent-facing plugin wiring.';
    } else if (File(p.join(root, 'skills.sh.json')).existsSync()) {
      try {
        final content = File(p.join(root, 'skills.sh.json')).readAsStringSync();
        if (content.contains(
              'https://skills.sh/schemas/skills.sh.schema.json',
            ) ||
            content.contains('skill_steward')) {
          archetype = 'meta_governance';
          archetypeConfidence = 'medium';
          details =
              'This is a meta/governance repository for skills, docs, policies, validators, or stewardship patterns.';
        }
      } on Object catch (_) {}
    }

    if (archetype == 'library') {
      final packagesDir = Directory(p.join(root, 'packages'));
      final toolDir = Directory(p.join(root, 'tool'));
      if (Directory(p.join(root, 'apps')).existsSync() ||
          Directory(p.join(root, 'app')).existsSync() ||
          Directory(p.join(root, 'web')).existsSync() ||
          Directory(p.join(root, 'ios')).existsSync() ||
          Directory(p.join(root, 'android')).existsSync()) {
        archetype = 'app';
        archetypeConfidence = 'medium';
        details =
            'This is an app repository. Product behavior, runtime validation, release evidence, and debugging paths are the primary stewardship surface.';
      } else if (packagesDir.existsSync() &&
          (File(p.join(root, 'pubspec.yaml')).existsSync() ||
              File(p.join(root, 'package.json')).existsSync())) {
        archetype = 'library';
        archetypeConfidence = 'medium';
        details =
            'This is a library or package workspace. Public APIs, tests, release notes, and consumer proof are the primary stewardship surface.';
      } else if (toolDir.existsSync()) {
        archetype = 'cli_tool';
        archetypeConfidence = 'medium';
        details =
            'This is a CLI/tool workspace. Commands, machine-readable output, effects, limits, and release artifacts are the primary stewardship surface.';
      } else {
        details = 'General library or codebase workspace.';
      }
    }

    if (config.archetype != null && config.archetype!.isNotEmpty) {
      archetype = config.archetype!;
      archetypeSource = 'configured in steward.yaml';
      archetypeConfidence = 'high';
      if (archetype == 'plugin') {
        details =
            'This repository exposes host integration metadata or agent-facing plugin wiring.';
      } else if (archetype == 'library') {
        details =
            'This is a library or package workspace. Public APIs, tests, release notes, and consumer proof are the primary stewardship surface.';
      } else if (archetype == 'cli_tool') {
        details =
            'This is a CLI/tool workspace. Commands, machine-readable output, effects, limits, and release artifacts are the primary stewardship surface.';
      } else if (archetype == 'harness') {
        details =
            'This is a harness/action-contract workspace. Typed actions, probes, benchmarks, and adapter parity are the primary stewardship surface.';
      } else if (archetype == 'meta_governance') {
        details =
            'This is a meta/governance repository for skills, docs, policies, validators, or stewardship patterns.';
      } else if (archetype == 'app') {
        details =
            'This is an app repository. Product behavior, runtime validation, release evidence, and debugging paths are the primary stewardship surface.';
      } else {
        details = 'Configured repository archetype.';
      }
    }

    write('- **Detected Archetype:** `$archetype`');
    write('- **Archetype Source:** $archetypeSource');
    write('- **Confidence:** $archetypeConfidence');
    write('- **Role:** $details');
    final quality = config.stewardship['quality'];
    if (quality is Map && quality['validate'] is String) {
      write('- **Native Quality Gate:** `${quality['validate']}`');
    }
    write();

    // 2. Active Local Skills
    write('## 📚 Active Installed Skills');
    write();
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
      } on Object catch (_) {}
    }

    if (localSkills.isNotEmpty) {
      localSkills.sort(
        (final a, final b) => p.basename(a.path).compareTo(p.basename(b.path)),
      );
      write('| Skill | Type | Description | Path |');
      write('|---|---|---|---|');
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
        } on Object catch (_) {}

        write('| `$name` | `$type` | $desc | `.agents/skills/$name/` |');
      }
    } else {
      write('_No skills installed. Run `steward install` to add skills._');
    }
    write();

    // 2a. Recommended Skills to Adopt
    write('## 💡 Recommended Skills to Adopt');
    write(
      'These base skills are recommended for installation to guide agents and maintain repository hygiene:',
    );
    write();

    final installedNames = localSkills
        .map((final d) => p.basename(d.path))
        .toSet();
    final skillLifecycle = config.stewardship['skill_lifecycle'];
    final installableSkills =
        skillLifecycle is Map && skillLifecycle['installable_skills'] == true;
    final recs = <Map<String, String>>[];

    if (!installedNames.contains('repo-quality-system-lifecycle')) {
      recs.add({
        'name': 'repo-quality-system-lifecycle',
        'why':
            'Establishes the broad repo stewardship baseline: archetype, docs lattice, native gates, evidence path, and maturity proof.',
      });
    }
    if (!installedNames.contains('repository-governance-lifecycle')) {
      recs.add({
        'name': 'repository-governance-lifecycle',
        'why':
            'Governs charter, AGENTS.md maps, ADRs, FAQs, ethics, and plan hygiene. Essential for maintaining repository stewardship.',
      });
    }
    if (installableSkills &&
        !installedNames.contains('skill-authoring-lifecycle')) {
      recs.add({
        'name': 'skill-authoring-lifecycle',
        'why':
            'Creates and audits installable SKILL.md packages while keeping skill boundaries small and discoverable.',
      });
    }
    if (!installedNames.contains('skill-source-citations')) {
      recs.add({
        'name': 'skill-source-citations',
        'why':
            'Persists source links and provenance so skill knowledge survives beyond one agent session.',
      });
    }
    if (installableSkills && !installedNames.contains('skill-eval-improve')) {
      recs.add({
        'name': 'skill-eval-improve',
        'why':
            'Adds Tier-1 rule-based evals, prompt suites, and bounded improvement loops for behavior-critical skills.',
      });
    }
    if (!installedNames.contains('mcp-harness-repo-maintainer')) {
      final harnessWhy =
          (archetype == 'plugin' || archetype == 'meta_governance')
          ? 'Tailored for agent-facing repositories that need typed contracts, bounded tools, and validation surfaces.'
          : 'Teaches CLI/MCP/core parity, mechanical gates, and local harness contracts without moving product runtime logic into Skill Steward.';
      recs.add({'name': 'mcp-harness-repo-maintainer', 'why': harnessWhy});
    }

    if (recs.isNotEmpty) {
      write('| Skill | Why it is useful / when to adopt |');
      write('|---|---|');
      for (final rec in recs) {
        write('| `${rec['name']}` | ${rec['why']} |');
      }
    } else {
      write(
        '✓ Excellent: All recommended base skills are currently installed.',
      );
    }
    write();

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
      } on Object catch (_) {}
    }

    if (exportedSkills.isNotEmpty) {
      write('## 📦 Exported Repository Skills');
      write(
        'These are custom agent skills authored in this repository to assist developers/agents:',
      );
      write();
      exportedSkills.sort(
        (final a, final b) => p.basename(a.path).compareTo(p.basename(b.path)),
      );
      write('| Skill | Type | Description | Path |');
      write('|---|---|---|---|');
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
        } on Object catch (_) {}

        write('| `$name` | `$type` | $desc | `skills/$name/` |');
      }
      write();
    }

    // 3. Documentation Lattice
    write('## 🧭 Documentation Lattice');
    write();
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
        write('- **$name**: [`$path`]($path)');
      });
    } else {
      write('_No core documentation guides detected._');
    }
    write();

    // 3a. Evidence route
    write('## 🧾 Evidence Route');
    write();
    final evidenceLedgers = <String>[];
    for (final relPath in [
      'docs/evidence/current-status.mdx',
      'docs/evidence/current-dogfood-status.mdx',
    ]) {
      if (File(p.join(root, relPath)).existsSync()) {
        evidenceLedgers.add(relPath);
      }
    }
    final qualityEvidence = _configuredEvidencePath(config);
    final docsEvidenceExists = Directory(
      p.join(root, 'docs', 'evidence'),
    ).existsSync();
    final localEvidenceExists =
        qualityEvidence != null &&
        Directory(p.join(root, qualityEvidence)).existsSync();

    if (evidenceLedgers.isNotEmpty) {
      write('- **Current Ledger:** `${evidenceLedgers.first}`');
      if (evidenceLedgers.length > 1) {
        for (final extra in evidenceLedgers.skip(1)) {
          write('- **Additional Ledger:** `$extra`');
        }
      }
    } else if (docsEvidenceExists || localEvidenceExists) {
      write(
        '- **Current Ledger:** none detected; add one when a current readiness or maturity claim needs a status pointer.',
      );
    } else {
      write(
        '- **Current Ledger:** none detected; start with native validation and create evidence only when a claim or blocker needs durable proof.',
      );
    }
    if (qualityEvidence != null && qualityEvidence.isNotEmpty) {
      write('- **Configured Evidence Path:** `$qualityEvidence`');
    }
    write(
      '- **Bootstrap:** `steward evidence init --minimal` creates only `docs/evidence/current-status.mdx`.',
    );
    write(
      '- **Routing:** ADR for decisions; FAQ/docs for standing guidance; check/tool/test for deterministic drift; evidence for real proof or blocked proof.',
    );
    write();

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
      } on Object catch (_) {}
    }

    if (activePlans.isNotEmpty) {
      write('## ⚠️ Active Plan Hygiene Alerts');
      write();
      write('> [!WARNING]');
      write(
        '> Stale/active plan files are present in the workspace. Clean these up before merging:',
      );
      for (final plan in activePlans) {
        write('> - `$plan`');
      }
    } else {
      write('## ✅ Plan Hygiene Status');
      write();
      write(
        '✓ Clean: No active or stale plan files detected in the workspace.',
      );
    }
    write();

    (outputSink ?? stdout).write(buffer.toString());
  }
}

String? _configuredEvidencePath(final StewardConfig config) {
  final quality = config.stewardship['quality'];
  if (quality is Map && quality['evidence'] is String) {
    return quality['evidence'] as String;
  }
  return null;
}
