import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Initializes Skill Steward inside a project workspace.
class AdoptCommand extends Command<void> {
  @override
  final name = 'adopt';

  @override
  final description =
      'Initialize Skill Steward configuration and agent map in the project.';

  @override
  Future<void> run() async {
    final currentDir = Directory.current.absolute.path;

    // 1. Setup skills.json
    final skillsJsonFile = File(p.join(currentDir, 'skills.json'));
    if (skillsJsonFile.existsSync()) {
      stdout.writeln('✓ skills.json already exists in project root.');
    } else {
      final initialConfig = {
        r'$schema': 'https://unpkg.com/skillman/skills_schema.json',
        'skills': [],
      };
      await skillsJsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(initialConfig),
      );
      stdout.writeln('Created skills.json in project root.');
    }

    // 2. Setup steward.yaml
    final stewardYamlFile = File(p.join(currentDir, 'steward.yaml'));
    final stewardYmlFile = File(p.join(currentDir, 'steward.yml'));
    if (stewardYamlFile.existsSync() || stewardYmlFile.existsSync()) {
      stdout.writeln('✓ steward.yaml already exists in project root.');
    } else {
      // Detect archetype to set a sensible default in steward.yaml
      String archetype = 'B — Platform libs';
      if (File(p.join(currentDir, 'plugin', 'mcp.json')).existsSync() ||
          File(p.join(currentDir, 'mcp.json')).existsSync()) {
        archetype = 'A — Product MCP';
      } else if (Directory(p.join(currentDir, 'tool')).existsSync() &&
          !Directory(p.join(currentDir, 'packages')).existsSync()) {
        archetype = 'C — CLI harness';
      } else if (File(p.join(currentDir, 'skills.sh.json')).existsSync()) {
        archetype = 'E — Meta steward';
      }

      final template = '''archetype: "$archetype"
preferredRunner: "" # E.g., just, make, npm

# Declared workspace validation checks
validators: []
# Example validator configuration:
# - type: disallowed-substrings
#   files:
#     - "**/pubspec.yaml"
#   exclude:
#     - "**/.dart_tool/**"
#     - "**/build/**"
#   substrings:
#     - "forbidden-override"
#   message: "FAIL: Forbidden path dependencies detected."
''';
      await stewardYamlFile.writeAsString(template);
      stdout.writeln('Created steward.yaml in project root.');
    }

    // 3. Scan for task runner configs
    final detectedConfigs = <String>[];
    for (final filename in [
      'Justfile',
      'justfile',
      'Makefile',
      'makefile',
      'package.json',
      'pubspec.yaml',
      'Cargo.toml',
      'pyproject.toml',
    ]) {
      if (File(p.join(currentDir, filename)).existsSync()) {
        detectedConfigs.add(filename);
      }
    }
    if (detectedConfigs.isNotEmpty) {
      stdout.writeln(
        'Detected workspace configurations: ${detectedConfigs.join(", ")}',
      );
    } else {
      stdout.writeln(
        'No standard task runner config detected. Consider creating a Justfile.',
      );
    }

    // 3. Create AGENTS.md
    final agentsMdFile = File(p.join(currentDir, 'AGENTS.md'));
    if (agentsMdFile.existsSync()) {
      stdout.writeln('✓ AGENTS.md already exists in project root.');
    } else {
      const agentsMdContent = '''
# AGENTS.md — Agent Entrypoint Map

Welcome! This project uses **Skill Steward** to govern agent-first workflows and skills.

## Operational Desk

Run the following commands to interact with the project's agentic tools:

- **Show operational map**: `steward map`
- **Validate workspace**: `steward validate --local`

## Active Skills

Skills are installed locally under `.agents/skills/`. You can view them using:
- `steward list`

For more information on the project charter and decisions:
- Read [NORTH_STAR.mdx](docs/NORTH_STAR.mdx) (if present)
- Read [ADR Index](docs/decisions/README) (if present)
''';
      await agentsMdFile.writeAsString(agentsMdContent);
      stdout.writeln('Created AGENTS.md in project root.');
    }

    stdout.writeln(
      '\nSkill Steward adoption complete. Try running "steward map" next.',
    );
  }
}
