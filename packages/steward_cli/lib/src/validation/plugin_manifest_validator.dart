import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Validates Skill Steward local plugin manifests.
///
/// These manifests are not vendor marketplace manifests. They document local
/// wiring bundles under plugins/{id}/ while keeping canonical SKILL.md files in
/// skills/{id}/.
Future<List<String>> validatePluginManifests(final String rootPath) async {
  final diagnostics = <String>[];
  final pluginsDir = Directory(p.join(rootPath, 'plugins'));
  if (!pluginsDir.existsSync()) {
    return diagnostics;
  }

  final entries =
      pluginsDir
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where((final dir) => !p.basename(dir.path).startsWith('.'))
          .toList()
        ..sort((final a, final b) => a.path.compareTo(b.path));

  for (final pluginDir in entries) {
    final pluginId = p.basename(pluginDir.path);
    final manifest = File(p.join(pluginDir.path, 'plugin.yaml'));
    if (!manifest.existsSync()) {
      diagnostics.add('plugins/$pluginId/plugin.yaml is required.');
      continue;
    }

    final duplicatedSkill = File(p.join(pluginDir.path, 'SKILL.md'));
    if (duplicatedSkill.existsSync()) {
      diagnostics.add(
        'plugins/$pluginId/SKILL.md is forbidden; keep skills canonical under skills/.',
      );
    }

    final data = _loadManifest(manifest, diagnostics);
    if (data == null) {
      continue;
    }

    _requireString(
      data,
      'schema',
      manifest,
      diagnostics,
      expected: 'steward/plugin-manifest/v1',
    );
    final id = _requireString(data, 'id', manifest, diagnostics);
    if (id != null && id != pluginId) {
      diagnostics.add(
        '${_rel(rootPath, manifest.path)}: id "$id" must match plugin directory "$pluginId".',
      );
    }
    _requireString(data, 'version', manifest, diagnostics);
    _requireString(data, 'description', manifest, diagnostics);

    final referencedSkills = _requireStringList(
      data,
      'referenced_skills',
      manifest,
      diagnostics,
    );
    for (final skillId in referencedSkills) {
      final skillFile = File(p.join(rootPath, 'skills', skillId, 'SKILL.md'));
      if (!skillFile.existsSync()) {
        diagnostics.add(
          '${_rel(rootPath, manifest.path)}: referenced_skills contains "$skillId", but skills/$skillId/SKILL.md does not exist.',
        );
      }
    }

    final targetAgents = _requireStringList(
      data,
      'target_agents',
      manifest,
      diagnostics,
    );
    if (targetAgents.isEmpty) {
      diagnostics.add(
        '${_rel(rootPath, manifest.path)}: target_agents must list at least one agent surface.',
      );
    }
    _validateTargets(rootPath, manifest, data, targetAgents, diagnostics);

    _validateWiringArtifacts(rootPath, pluginDir.path, data, diagnostics);
    _validateHasWiring(rootPath, manifest, data, diagnostics);
    _validateLifecycleAction(data, 'install', manifest, diagnostics);
    _validateLifecycleAction(data, 'update', manifest, diagnostics);
    _validateLifecycleAction(data, 'uninstall', manifest, diagnostics);
  }

  return diagnostics;
}

Map<String, dynamic>? _loadManifest(
  final File manifest,
  final List<String> diagnostics,
) {
  try {
    final parsed = loadYaml(manifest.readAsStringSync());
    if (parsed is! YamlMap) {
      diagnostics.add('${manifest.path}: plugin.yaml must be a YAML map.');
      return null;
    }
    return Map<String, dynamic>.from(parsed);
  } on Object catch (error) {
    diagnostics.add('${manifest.path}: failed to parse plugin.yaml: $error');
    return null;
  }
}

String? _requireString(
  final Map<String, dynamic> data,
  final String key,
  final File manifest,
  final List<String> diagnostics, {
  final String? expected,
}) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) {
    diagnostics.add('${manifest.path}: $key must be a non-empty string.');
    return null;
  }
  if (expected != null && value != expected) {
    diagnostics.add('${manifest.path}: $key must be "$expected".');
  }
  return value;
}

List<String> _requireStringList(
  final Map<String, dynamic> data,
  final String key,
  final File manifest,
  final List<String> diagnostics,
) {
  final value = data[key];
  if (value is! YamlList && value is! List) {
    diagnostics.add('${manifest.path}: $key must be a non-empty string list.');
    return const [];
  }

  final items = <String>[];
  for (final item in value as Iterable) {
    if (item is String && item.trim().isNotEmpty) {
      items.add(item);
    } else {
      diagnostics.add('${manifest.path}: $key contains a non-string item.');
    }
  }
  if (items.isEmpty) {
    diagnostics.add('${manifest.path}: $key must not be empty.');
  }
  return items;
}

void _validateTargets(
  final String rootPath,
  final File manifest,
  final Map<String, dynamic> data,
  final List<String> targetAgents,
  final List<String> diagnostics,
) {
  final targets = data['targets'];
  if (targets == null) {
    return;
  }
  if (targets is! YamlMap && targets is! Map) {
    diagnostics.add('${_rel(rootPath, manifest.path)}: targets must be a map.');
    return;
  }
  for (final key in (targets as Map).keys) {
    final target = key.toString();
    if (!targetAgents.contains(target)) {
      diagnostics.add(
        '${_rel(rootPath, manifest.path)}: targets.$target must also be listed in target_agents.',
      );
    }
  }
}

void _validateHasWiring(
  final String rootPath,
  final File manifest,
  final Map<String, dynamic> data,
  final List<String> diagnostics,
) {
  final targets = data['targets'];
  final artifacts = data['wiring_artifacts'];
  final generatedArtifacts = data['generated_artifacts'];

  bool hasEntries(final Object? value) {
    if (value is YamlMap) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    if (value is YamlList) {
      return value.isNotEmpty;
    }
    if (value is List) {
      return value.isNotEmpty;
    }
    return false;
  }

  if (!hasEntries(targets) &&
      !hasEntries(artifacts) &&
      !hasEntries(generatedArtifacts)) {
    diagnostics.add(
      '${_rel(rootPath, manifest.path)}: plugin manifests must declare runtime wiring; skills-only bundles belong in skills.sh.json.',
    );
  }
}

void _validateWiringArtifacts(
  final String rootPath,
  final String pluginPath,
  final Map<String, dynamic> data,
  final List<String> diagnostics,
) {
  final artifacts = data['wiring_artifacts'];
  if (artifacts == null) {
    return;
  }
  if (artifacts is! YamlList && artifacts is! List) {
    diagnostics.add(
      '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring_artifacts must be a list.',
    );
    return;
  }
  for (final artifact in artifacts as Iterable) {
    if (artifact is! YamlMap && artifact is! Map) {
      diagnostics.add(
        '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring_artifacts entries must be maps.',
      );
      continue;
    }
    final map = Map<String, dynamic>.from(artifact as Map);
    final artifactPath = map['path'];
    final expectedSha256 = map['sha256'];
    if (artifactPath is! String || artifactPath.trim().isEmpty) {
      diagnostics.add(
        '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring_artifacts[].path must be a non-empty string.',
      );
      continue;
    }
    if (p.isAbsolute(artifactPath) || artifactPath.contains('..')) {
      diagnostics.add(
        '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring artifact "$artifactPath" must stay inside the plugin directory.',
      );
      continue;
    }
    final file = File(p.join(pluginPath, artifactPath));
    if (!file.existsSync()) {
      diagnostics.add(
        '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring artifact "$artifactPath" does not exist.',
      );
      continue;
    }
    if (expectedSha256 is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedSha256)) {
      diagnostics.add(
        '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring artifact "$artifactPath" must declare a 64-character lowercase sha256.',
      );
      continue;
    }
    final actual = sha256.convert(file.readAsBytesSync()).toString();
    if (actual != expectedSha256) {
      diagnostics.add(
        '${_rel(rootPath, p.join(pluginPath, 'plugin.yaml'))}: wiring artifact "$artifactPath" sha256 mismatch: expected $expectedSha256, got $actual.',
      );
    }
  }
}

void _validateLifecycleAction(
  final Map<String, dynamic> data,
  final String key,
  final File manifest,
  final List<String> diagnostics,
) {
  final value = data[key];
  if (value is! YamlMap && value is! Map) {
    diagnostics.add('${manifest.path}: $key must declare actions.');
    return;
  }
  final map = Map<String, dynamic>.from(value as Map);
  final actions = map['actions'];
  if (actions is! YamlList && actions is! List) {
    diagnostics.add('${manifest.path}: $key.actions must be a string list.');
    return;
  }
  final hasAction = (actions as Iterable).any(
    (final action) => action is String && action.trim().isNotEmpty,
  );
  if (!hasAction) {
    diagnostics.add('${manifest.path}: $key.actions must not be empty.');
  }
}

String _rel(final String rootPath, final String path) =>
    p.relative(path, from: rootPath).replaceAll(r'\', '/');
