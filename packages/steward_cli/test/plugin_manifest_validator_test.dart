import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/validation/validation.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('plugin_manifest_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('accepts v1 plugin manifest that references canonical skills', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(diagnostics, isEmpty);
  });

  test('rejects unknown referenced skills and copied SKILL.md files', () async {
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'missing-skill',
    );
    await File(
      p.join(tempDir.path, 'plugins', 'steward-validate-on-save', 'SKILL.md'),
    ).writeAsString('# copied skill');

    final diagnostics = await validatePluginManifests(tempDir.path);
    final joined = diagnostics.join('\n');

    expect(joined, contains('referenced_skills contains "missing-skill"'));
    expect(joined, contains('SKILL.md is forbidden'));
  });

  test('rejects target maps outside declared target_agents', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      targetKey: 'claude',
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains('targets.claude must also be listed in target_agents'),
    );
  });

  test('rejects skills-only plugin manifests', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      includeTargets: false,
      includeWiringArtifacts: false,
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains('skills-only bundles belong in skills.sh.json'),
    );
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

Future<void> _writePlugin(
  final String root, {
  required final String id,
  required final String skillId,
  final String targetAgent = 'cursor',
  final String targetKey = 'cursor',
  final bool includeTargets = true,
  final bool includeWiringArtifacts = true,
}) async {
  final dir = Directory(p.join(root, 'plugins', id));
  await Directory(p.join(dir.path, 'hooks')).create(recursive: true);
  await File(p.join(dir.path, 'hooks', 'example.sh')).writeAsString('');
  await File(p.join(dir.path, 'hooks.json.snippet')).writeAsString('{}');
  await File(p.join(dir.path, 'plugin.yaml')).writeAsString('''
schema: steward/plugin-manifest/v1
id: $id
version: 0.1.0
description: Test plugin
referenced_skills:
  - $skillId
target_agents:
  - $targetAgent
${includeTargets ? '''
targets:
  $targetKey:
    hooks:
      - event: afterFileEdit
        script: hooks/example.sh
''' : ''}
${includeWiringArtifacts ? '''
wiring_artifacts:
  - path: hooks/example.sh
    sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
''' : ''}
install:
  actions:
    - merge_cursor_hooks_json
update:
  actions:
    - replace_matching_cursor_hook
uninstall:
  actions:
    - remove_matching_cursor_hook
''');
}
