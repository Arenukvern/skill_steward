import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/bundle_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('steward_bundle_test_');
    await File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsString(jsonEncode({'skills': []}));
    await File(p.join(tempDir.path, 'steward.yaml')).writeAsString('''
schema: steward/v1
repo:
  id: sample_repo
  archetype: meta_steward
harness:
  name: steward
  mode: cli
  entrypoints:
    cli: steward
adoption:
  status: adopting
  owner: sample_repo
  gate:
    pillar: quality
stewardship:
  governance: {charter: AGENTS.md}
  knowledge: {docs_map: AGENTS.md}
  skill_lifecycle: {installable_skills: true}
  quality: {validate: steward validate}
  harness: {enabled: true}
  release: {changelog: CHANGELOG.md}
  review_handoff: {moe_required_for_architecture: true}
  strategic_alignment: {vision_source: AGENTS.md}
  security: {action_effects: required}
  org: {owners: AGENTS.md}
actions:
  doctor.local:
    kind: command
    desc: Inspect repo.
    command: {argv: [steward, doctor, --json], shell: false}
    cwd: .
    effects:
      fs_read: ["."]
      fs_write: []
      git: read
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
    evidence: {redact: []}
probes:
  quick:
    profile: quick
    actions: [doctor.local]
diagnostics:
  cases: {}
unknown_cases:
  path: .steward/unknown-cases
  retention: local
provenance:
  dependencies: []
  artifacts: []
  benchmarks: []
''');
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'v1 bundle writes deterministic descriptors without installing',
    () async {
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(BundleCommand(buffer, tempDir));

      await runner.run(['bundle']);

      expect(buffer.toString(), contains('Generated 1 plugin bundle(s)'));
      expect(File(p.join(tempDir.path, '.clinerules')).existsSync(), isFalse);
      expect(
        File(
          p.join(tempDir.path, '.cursor', 'rules', 'steward.mdc'),
        ).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(tempDir.path, '.cursor', 'hooks.json')).existsSync(),
        isFalse,
      );

      final bundleFile = File(
        p.join(
          tempDir.path,
          '.steward',
          'bundles',
          'steward-validate-on-save.bundle.json',
        ),
      );
      expect(bundleFile.existsSync(), isTrue);
      final firstContent = await bundleFile.readAsString();
      final bundle = jsonDecode(firstContent) as Map<String, dynamic>;

      expect(bundle['schema'], 'steward/plugin-bundle/v1');
      expect(bundle['id'], 'steward-validate-on-save');
      expect(
        bundle['source_manifest'],
        'plugins/steward-validate-on-save/plugin.yaml',
      );
      expect(
        bundle['source_manifest_sha256'],
        matches(RegExp(r'^[a-f0-9]{64}$')),
      );
      final referencedSkills = bundle['referenced_skills'] as List;
      expect(
        referencedSkills.single,
        containsPair('id', 'skill-authoring-lifecycle'),
      );
      expect(
        referencedSkills.single,
        containsPair('path', 'skills/skill-authoring-lifecycle/SKILL.md'),
      );
      expect(
        (referencedSkills.single as Map)['sha256'],
        matches(RegExp(r'^[a-f0-9]{64}$')),
      );
      expect(bundle['target_agents'], ['cursor']);
      expect((bundle['wiring_artifacts'] as List).single, {
        'path': 'hooks/example.sh',
        'source_path': 'plugins/steward-validate-on-save/hooks/example.sh',
        'sha256':
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      });
      expect((bundle['lifecycle'] as Map)['uninstall'], ['remove_cursor_hook']);

      await runner.run(['bundle']);
      expect(await bundleFile.readAsString(), firstContent);
    },
  );

  test(
    'v1 bundle --stdout emits deterministic index without writing files',
    () async {
      final first = StringBuffer();
      final second = StringBuffer();
      final firstRunner = CommandRunner<void>('steward', 'test')
        ..addCommand(BundleCommand(first, tempDir));
      final secondRunner = CommandRunner<void>('steward', 'test')
        ..addCommand(BundleCommand(second, tempDir));

      await firstRunner.run(['bundle', '--stdout']);
      await secondRunner.run(['bundle', '--stdout']);

      expect(second.toString(), first.toString());
      final payload = jsonDecode(first.toString()) as Map<String, dynamic>;
      expect(payload['schema'], 'steward/plugin-bundle-index/v1');
      final bundles = payload['bundles'] as List;
      expect(bundles.single, containsPair('id', 'steward-validate-on-save'));
      expect(Directory(p.join(tempDir.path, '.steward')).existsSync(), isFalse);
    },
  );

  test('v1 bundle refuses invalid plugin manifests', () async {
    await File(
      p.join(
        tempDir.path,
        'plugins',
        'steward-validate-on-save',
        'plugin.yaml',
      ),
    ).writeAsString('''
schema: steward/plugin-manifest/v1
id: steward-validate-on-save
version: 0.1.0
description: Invalid plugin
referenced_skills:
  - missing-skill
target_agents:
  - cursor
targets:
  cursor:
    hooks: []
wiring_artifacts:
  - path: hooks/example.sh
    sha256: E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
install:
  actions: [install_referenced_skills]
update:
  actions: [refresh_referenced_skills]
uninstall:
  actions: [remove_cursor_hook]
''');

    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(BundleCommand(StringBuffer(), tempDir));

    expect(() => runner.run(['bundle']), throwsA(isA<UsageException>()));
  });
}

Future<void> _writeSkill(final String root, final String id) async {
  final dir = Directory(p.join(root, 'skills', id));
  await dir.create(recursive: true);
  await File(p.join(dir.path, 'SKILL.md')).writeAsString('''
---
name: $id
description: Test skill description
---

# $id
''');
}

Future<void> _writePlugin(final String root) async {
  final dir = Directory(p.join(root, 'plugins', 'steward-validate-on-save'));
  await Directory(p.join(dir.path, 'hooks')).create(recursive: true);
  await File(p.join(dir.path, 'hooks', 'example.sh')).writeAsString('');
  await File(p.join(dir.path, 'plugin.yaml')).writeAsString('''
schema: steward/plugin-manifest/v1
id: steward-validate-on-save
version: 0.1.0
description: Cursor hook bundle
referenced_skills:
  - skill-authoring-lifecycle
target_agents:
  - cursor
targets:
  cursor:
    hooks:
      - event: afterFileEdit
        script: hooks/example.sh
wiring_artifacts:
  - path: hooks/example.sh
    sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
conflict_policy: fail
install:
  actions:
    - install_referenced_skills
    - merge_cursor_hooks_json
update:
  actions:
    - refresh_referenced_skills
    - verify_wiring_artifacts
uninstall:
  actions:
    - remove_cursor_hook
reproducibility:
  source: git+https://github.com/arenukvern/skill_steward.git
  built_from:
    - plugins/steward-validate-on-save/plugin.yaml
''');
}
