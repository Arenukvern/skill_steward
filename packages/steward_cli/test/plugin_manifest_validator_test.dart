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

  test('accepts current steward-validate-on-save manifest', () async {
    final diagnostics = await validatePluginManifests(_repoRoot());

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

  test('rejects referenced skill path segments', () async {
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: '../outside-skill',
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains('referenced_skills contains unsafe skill id "../outside-skill"'),
    );
  });

  test('reports referenced skill symlink escapes as diagnostics', () async {
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
    );
    final outsideDir = Directory.systemTemp.createTempSync(
      'plugin_manifest_outside_skill_',
    );
    addTearDown(() {
      if (outsideDir.existsSync()) {
        outsideDir.deleteSync(recursive: true);
      }
    });
    final outside = File(p.join(outsideDir.path, 'outside-skill.md'))
      ..writeAsStringSync('# outside');
    final skillDir = Directory(
      p.join(tempDir.path, 'skills', 'skill-authoring-lifecycle'),
    );
    await skillDir.create(recursive: true);
    await Link(p.join(skillDir.path, 'SKILL.md')).create(outside.path);

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains('referenced skill "skill-authoring-lifecycle" resolves outside'),
    );
  });

  test('rejects target hook scripts outside plugin directory', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      targetScriptPath: '../outside.sh',
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains(
        'targets.cursor.hooks[0].script "../outside.sh" must stay inside',
      ),
    );
  });

  test('rejects unnormalized target hook scripts', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      targetScriptPath: 'hooks/../hooks/example.sh',
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains(
        'targets.cursor.hooks[0].script "hooks/../hooks/example.sh" must be normalized as "hooks/example.sh"',
      ),
    );
  });

  test('rejects absolute target hook config snippets', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      configSnippetPath: p.join(tempDir.path, 'hooks.json.snippet'),
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains('targets.cursor.hooks[0].config_snippet'),
    );
    expect(diagnostics.join('\n'), contains('must be relative'));
  });

  test('rejects target hook scripts that escape through symlinks', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    final outside = File(p.join(tempDir.path, 'outside-hook.sh'))
      ..writeAsStringSync('');
    final pluginDir = Directory(
      p.join(tempDir.path, 'plugins', 'steward-validate-on-save'),
    );
    await Directory(p.join(pluginDir.path, 'hooks')).create(recursive: true);
    await Link(
      p.join(pluginDir.path, 'hooks', 'escape.sh'),
    ).create(outside.path);
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      artifactPath: 'hooks/escape.sh',
      targetScriptPath: 'hooks/escape.sh',
      createArtifact: false,
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains(
        'targets.cursor.hooks[0].script "hooks/escape.sh" must stay inside',
      ),
    );
  });

  test(
    'rejects target hook scripts not declared as wiring artifacts',
    () async {
      await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
      await _writePlugin(
        tempDir.path,
        id: 'steward-validate-on-save',
        skillId: 'skill-authoring-lifecycle',
        targetScriptPath: 'hooks/unlisted.sh',
      );

      final diagnostics = await validatePluginManifests(tempDir.path);

      expect(
        diagnostics.join('\n'),
        contains(
          'targets.cursor.hooks[0].script "hooks/unlisted.sh" must be listed',
        ),
      );
    },
  );

  test('rejects wiring artifacts that escape through symlinks', () async {
    await _writeSkill(tempDir.path, 'skill-authoring-lifecycle');
    final outside = File(p.join(tempDir.path, 'outside-hook.sh'))
      ..writeAsStringSync('');
    final pluginDir = Directory(
      p.join(tempDir.path, 'plugins', 'steward-validate-on-save'),
    );
    await Directory(p.join(pluginDir.path, 'hooks')).create(recursive: true);
    await Link(
      p.join(pluginDir.path, 'hooks', 'escape.sh'),
    ).create(outside.path);
    await _writePlugin(
      tempDir.path,
      id: 'steward-validate-on-save',
      skillId: 'skill-authoring-lifecycle',
      artifactPath: 'hooks/escape.sh',
      createArtifact: false,
    );

    final diagnostics = await validatePluginManifests(tempDir.path);

    expect(
      diagnostics.join('\n'),
      contains('wiring artifact "hooks/escape.sh" must stay inside'),
    );
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

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(
      p.join(dir.path, 'plugins', 'steward-validate-on-save', 'plugin.yaml'),
    ).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find repository root.');
    }
    dir = parent;
  }
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
  final String artifactPath = 'hooks/example.sh',
  final String targetScriptPath = 'hooks/example.sh',
  final String? configSnippetPath,
  final bool createArtifact = true,
}) async {
  final dir = Directory(p.join(root, 'plugins', id));
  await Directory(p.join(dir.path, 'hooks')).create(recursive: true);
  if (createArtifact) {
    final artifact = File(p.join(dir.path, artifactPath));
    await artifact.parent.create(recursive: true);
    await artifact.writeAsString('');
  }
  await File(p.join(dir.path, 'hooks.json.snippet')).writeAsString('{}');
  final configSnippetYaml = configSnippetPath == null
      ? ''
      : '\n        config_snippet: $configSnippetPath';
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
        script: $targetScriptPath$configSnippetYaml
''' : ''}
${includeWiringArtifacts ? '''
wiring_artifacts:
  - path: $artifactPath
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
