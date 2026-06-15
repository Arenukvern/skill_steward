import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/plugin_manifest_validator.dart';
import '../validation/steward_config.dart';
import '../yaml_utils.dart';

/// Compiles local Skill Steward distribution manifests.
class BundleCommand extends Command<void> {
  BundleCommand([final StringBuffer? output, final Directory? rootDir])
    : _output = output,
      _rootDir = rootDir {
    argParser
      ..addFlag(
        'stdout',
        negatable: false,
        help: 'Print the v1 plugin bundle index instead of writing files.',
      )
      ..addOption(
        'output-dir',
        defaultsTo: '.steward/bundles',
        help: 'Directory for v1 plugin bundle descriptors.',
      );
  }

  final StringBuffer? _output;
  final Directory? _rootDir;

  @override
  final name = 'bundle';

  @override
  final description = 'Compiles local Skill Steward bundle manifests.';

  @override
  Future<void> run() async {
    final root = _rootDir?.path ?? findRepoRoot(Directory.current);
    final config = await StewardConfig.load(root);

    if (config.isV1) {
      await _runV1(root);
      return;
    }

    await _runLegacy(root, config);
  }

  Future<void> _runV1(final String root) async {
    final diagnostics = await validatePluginManifests(root);
    if (diagnostics.isNotEmpty) {
      throw UsageException(
        'Plugin bundle manifests are invalid:\n${diagnostics.join('\n')}',
        usage,
      );
    }

    final bundles = await _compilePluginBundles(root);
    final stdoutIndex = <String, dynamic>{
      'schema': 'steward/plugin-bundle-index/v1',
      'bundles': bundles,
    };

    if (argResults?['stdout'] == true) {
      _writeln(const JsonEncoder.withIndent('  ').convert(stdoutIndex));
      return;
    }

    final outputDirArg = argResults?['output-dir'] as String;
    final outputDirName = _normalizeOutputDir(outputDirArg);
    final String outputPath;
    try {
      outputPath = resolveUnderRoot(root, outputDirName);
    } on Object {
      throw UsageException(
        '--output-dir must be a repository-relative path.',
        usage,
      );
    }

    final outputDir = Directory(outputPath);
    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    final indexEntries = <Map<String, dynamic>>[];
    for (final bundle in bundles) {
      final id = bundle['id'] as String;
      final fileName = '$id.bundle.json';
      final relPath = p.join(outputDirName, fileName).replaceAll(r'\', '/');
      final content = '${const JsonEncoder.withIndent('  ').convert(bundle)}\n';
      await File(p.join(outputDir.path, fileName)).writeAsString(content);
      indexEntries.add({
        'id': id,
        'version': bundle['version'],
        'path': relPath,
        'sha256': sha256.convert(utf8.encode(content)).toString(),
        'source_manifest': bundle['source_manifest'],
      });
    }

    final fileIndex = <String, dynamic>{
      'schema': 'steward/plugin-bundle-index/v1',
      'bundles': indexEntries,
    };
    await File(p.join(outputDir.path, 'index.json')).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(fileIndex)}\n',
    );
    _writeln('Generated ${bundles.length} plugin bundle(s) in $outputDirName.');
  }

  String _normalizeOutputDir(final String value) {
    if (p.isAbsolute(value)) {
      throw UsageException(
        '--output-dir must be a repository-relative path.',
        usage,
      );
    }
    final normalized = p.normalize(value).replaceAll(r'\', '/');
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized.startsWith('..')) {
      throw UsageException(
        '--output-dir must be a non-empty repository-relative path.',
        usage,
      );
    }
    return normalized;
  }

  Future<void> _runLegacy(final String root, final StewardConfig config) async {
    if (config.skillsDistribution.isEmpty) {
      throw UsageException(
        'Missing skills_distribution in steward.yaml.',
        usage,
      );
    }

    final sourceDirName =
        config.skillsDistribution['source_dir'] as String? ?? 'skills/';
    final outputName =
        config.skillsDistribution['output'] as String? ?? 'skills.sh.json';

    final String sourcePath;
    final String outPath;
    try {
      sourcePath = resolveUnderRoot(root, sourceDirName);
      outPath = resolveUnderRoot(root, outputName);
    } on Object {
      throw UsageException(
        'skills_distribution paths must be repository-relative.',
        usage,
      );
    }

    final sourceDir = Directory(sourcePath);
    if (!sourceDir.existsSync()) {
      throw UsageException(
        'Source directory ${sourceDir.path} does not exist.',
        usage,
      );
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

    final outFile = File(outPath);
    await outFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(outMap)}\n',
    );
    _writeln('Successfully bundled ${skills.length} skills into $outputName.');

    final legacyPipelines = config.pipelines.keys
        .map((final k) {
          final pipeline = config.pipelines[k];
          final desc = pipeline is Map ? pipeline['desc'] : '';
          return '- $k: $desc';
        })
        .join('\n');
    final instructions =
        'You are operating in a repository governed by Skill Steward.\n'
        'Prefer deterministic CLI validators, documented skills, and typed actions. '
        'Do not run complex bash manually, and do not permanently mutate steward.yaml through MCP.\n\n'
        'Legacy Pipelines (experimental; require explicit human approval):\n'
        '${legacyPipelines.isEmpty ? '- none' : legacyPipelines}\n\n'
        'Available Skills:\n${skills.map((final s) => '- $s').join('\n')}';

    final clineFile = File(p.join(root, '.clinerules'));
    await clineFile.writeAsString('$instructions\n');
    _writeln('Generated .clinerules');

    final cursorDir = Directory(p.join(root, '.cursor', 'rules'));
    if (!cursorDir.existsSync()) {
      cursorDir.createSync(recursive: true);
    }
    final cursorFile = File(p.join(cursorDir.path, 'steward.mdc'));
    final cursorContent =
        '---\ndescription: Global Steward Governance\nglobs: *\n---\n\n$instructions\n';
    await cursorFile.writeAsString(cursorContent);
    _writeln('Generated .cursor/rules/steward.mdc');
  }

  Future<List<Map<String, dynamic>>> _compilePluginBundles(
    final String root,
  ) async {
    final pluginsDir = Directory(p.join(root, 'plugins'));
    if (!pluginsDir.existsSync()) {
      return const [];
    }

    final pluginDirs =
        pluginsDir
            .listSync(followLinks: false)
            .whereType<Directory>()
            .where((final dir) => !p.basename(dir.path).startsWith('.'))
            .toList()
          ..sort((final a, final b) => a.path.compareTo(b.path));

    final bundles = <Map<String, dynamic>>[];
    for (final pluginDir in pluginDirs) {
      final manifest = File(p.join(pluginDir.path, 'plugin.yaml'));
      final data = _yamlMapToDart(loadYaml(await manifest.readAsString()));
      final id = data['id'] as String;
      final relManifest = _rel(root, manifest.path);

      bundles.add({
        'schema': 'steward/plugin-bundle/v1',
        'id': id,
        'version': '${data['version']}',
        'description': data['description'],
        'source_manifest': relManifest,
        'source_manifest_sha256': await _fileSha256(manifest),
        'referenced_skills': await _referencedSkills(root, data),
        'target_agents': List<String>.from(data['target_agents'] as List),
        if (data['targets'] != null) 'targets': data['targets'],
        'wiring_artifacts': await _wiringArtifacts(root, pluginDir, data),
        'lifecycle': {
          'install': _actions(data, 'install'),
          'update': _actions(data, 'update'),
          'uninstall': _actions(data, 'uninstall'),
        },
        'generated_artifacts': data['generated_artifacts'] ?? const [],
        'managed_blocks': data['managed_blocks'] ?? const [],
        if (data['conflict_policy'] != null)
          'conflict_policy': data['conflict_policy'],
        if (data['reproducibility'] != null)
          'reproducibility': data['reproducibility'],
      });
    }

    return bundles;
  }

  Future<List<Map<String, dynamic>>> _referencedSkills(
    final String root,
    final Map<String, dynamic> data,
  ) async {
    final skills = List<String>.from(data['referenced_skills'] as List)..sort();
    final entries = <Map<String, dynamic>>[];
    for (final id in skills) {
      final path = p.join('skills', id, 'SKILL.md').replaceAll(r'\', '/');
      final resolved = resolveUnderRoot(root, path);
      entries.add({
        'id': id,
        'path': path,
        'sha256': await _fileSha256(File(resolved)),
      });
    }
    return entries;
  }

  Future<List<Map<String, dynamic>>> _wiringArtifacts(
    final String root,
    final Directory pluginDir,
    final Map<String, dynamic> data,
  ) async {
    final raw = data['wiring_artifacts'];
    if (raw is! List) {
      return const [];
    }
    final entries = <Map<String, dynamic>>[];
    for (final item in raw) {
      final map = Map<String, dynamic>.from(item as Map);
      final artifactPath = map['path'] as String;
      final resolvedArtifactPath = resolveUnderRoot(
        pluginDir.path,
        artifactPath,
      );
      final sourcePath = _rel(root, resolvedArtifactPath);
      entries.add({
        'path': artifactPath,
        'source_path': sourcePath,
        'sha256': map['sha256'],
      });
    }
    entries.sort(
      (final a, final b) =>
          (a['path'] as String).compareTo(b['path'] as String),
    );
    return entries;
  }

  List<String> _actions(final Map<String, dynamic> data, final String key) {
    final lifecycle = Map<String, dynamic>.from(data[key] as Map);
    return List<String>.from(lifecycle['actions'] as List);
  }

  Map<String, dynamic> _yamlMapToDart(final Object? value) {
    final converted = yamlToDart(value);
    if (converted is Map<String, dynamic>) {
      return converted;
    }
    throw UsageException('plugin.yaml must contain a YAML map.', usage);
  }

  Future<String> _fileSha256(final File file) async =>
      sha256.convert(await file.readAsBytes()).toString();

  String _rel(final String root, final String path) {
    final rootPath = Directory(root).resolveSymbolicLinksSync();
    final resolvedPath = resolveExistingPath(path) ?? p.normalize(path);
    return p.relative(resolvedPath, from: rootPath).replaceAll(r'\', '/');
  }

  void _writeln(final Object? value) {
    final output = _output;
    if (output == null) {
      stdout.writeln(value);
    } else {
      output.writeln(value);
    }
  }
}
