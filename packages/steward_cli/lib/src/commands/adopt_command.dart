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
      // Detect archetype to set a sensible default in steward.yaml.
      String archetype = 'platform_lib';
      if (File(p.join(currentDir, 'plugin', 'mcp.json')).existsSync() ||
          File(p.join(currentDir, 'mcp.json')).existsSync()) {
        archetype = 'product_mcp';
      } else if (Directory(p.join(currentDir, 'tool')).existsSync() &&
          !Directory(p.join(currentDir, 'packages')).existsSync()) {
        archetype = 'cli_harness';
      } else if (File(p.join(currentDir, 'skills.sh.json')).existsSync()) {
        archetype = 'meta_steward';
      }

      final repoId = p
          .basename(currentDir)
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9_-]+'), '_')
          .replaceAll(RegExp('_+'), '_');
      final template =
          '''
schema: steward/v1
repo:
  id: $repoId
  archetype: $archetype

harness:
  name: steward
  mode: cli
  entrypoints:
    cli: steward

adoption:
  status: adopting
  owner: $repoId
  gate:
    pillar: quality

stewardship:
  governance:
    charter: AGENTS.md
    adr_dir: docs/decisions
  knowledge:
    docs_map: AGENTS.md
    source_policy: required_for_external_claims
  skill_lifecycle:
    installable_skills: true
    registry: skills.json
  quality:
    validate: steward validate --local
    skill_eval: steward eval
  harness:
    enabled: true
    action_contract: actions
  release:
    changelog: CHANGELOG.md
    artifact_provenance: required
  review_handoff:
    moe_required_for_architecture: true
  strategic_alignment:
    vision_source: AGENTS.md
    success_evidence: required
  security:
    action_effects: required
    redaction: steward/redaction/v1
  org:
    owners: AGENTS.md

actions:
  doctor.local:
    kind: command
    desc: Inspect Steward adoption state without running repository actions.
    command:
      argv: [steward, doctor, --json]
      shell: false
    cwd: .
    effects:
      fs_read: ["."]
      fs_write: []
      git: false
      network: false
      secrets: false
      destructive: false
    safety:
      class: observe
      default_policy: auto
      requires_confirmation: false
    limits:
      timeout_ms: 10000
      max_output_bytes: 200000
    outputs:
      - id: stdout
        kind: stream
        required: true
        retention: summary
        format: json
    evidence:
      redact: []

probes:
  quick:
    profile: quick
    actions: [doctor.local]

diagnostics:
  cases: {}

unknown_cases:
  path: .steward/unknown-cases/
  retention: local

provenance:
  dependencies: []
  artifacts: []
  benchmarks: []
'''
              .trimLeft();
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
