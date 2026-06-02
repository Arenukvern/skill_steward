import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Glob-to-RegExp translation utility to avoid external package dependencies.
RegExp globToRegex(String pattern) {
  var escaped = pattern
      .replaceAll(r'\', r'\\')
      .replaceAll(r'.', r'\.')
      .replaceAll(r'+', r'\+')
      .replaceAll(r'$', r'\$')
      .replaceAll(r'^', r'\^')
      .replaceAll(r'[', r'\[')
      .replaceAll(r']', r'\]')
      .replaceAll(r'(', r'\(')
      .replaceAll(r')', r'\)')
      .replaceAll(r'{', r'\{')
      .replaceAll(r'}', r'\}')
      .replaceAll(r'|', r'\|');

  escaped = escaped.replaceAll('**/', 'DOUBLE_STAR_SLASH');
  escaped = escaped.replaceAll('/**', 'SLASH_DOUBLE_STAR');
  escaped = escaped.replaceAll('**', 'DOUBLE_STAR');
  escaped = escaped.replaceAll('*', 'SINGLE_STAR');

  escaped = escaped.replaceAll('DOUBLE_STAR_SLASH', '(?:.*/)?');
  escaped = escaped.replaceAll('SLASH_DOUBLE_STAR', '(?:/.*)?');
  escaped = escaped.replaceAll('DOUBLE_STAR', '.*');
  escaped = escaped.replaceAll('SINGLE_STAR', '[^/]*');

  return RegExp('^$escaped\$');
}

class CustomValidator {
  CustomValidator({
    required this.type,
    required this.files,
    this.exclude = const [],
    this.substrings = const [],
    required this.message,
  });

  final String type;
  final List<String> files;
  final List<String> exclude;
  final List<String> substrings;
  final String message;

  static CustomValidator? fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    final filesList = map['files'] as List?;
    final excludeList = map['exclude'] as List?;
    final substringsList = map['substrings'] as List?;
    final message = map['message'] as String?;

    if (type == null || filesList == null || message == null) return null;

    return CustomValidator(
      type: type,
      files: filesList.cast<String>(),
      exclude: excludeList?.cast<String>() ?? const [],
      substrings: substringsList?.cast<String>() ?? const [],
      message: message,
    );
  }

  /// Runs this validator over the workspace root.
  Future<List<String>> validate(String rootPath) async {
    final errors = <String>[];
    if (type != 'disallowed-substrings') return errors;

    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) return errors;

    final filePatterns = files.map(globToRegex).toList();
    final excludePatterns = exclude.map(globToRegex).toList();

    final List<File> filesToScan = [];
    final ignoreDirNames = {
      '.git',
      '.agents',
      '.steward_temp',
      '.dart_tool',
      'node_modules',
      'build',
      'target',
    };

    await _findFilesRecursive(
      rootDir,
      rootPath,
      filesToScan,
      ignoreDirNames,
      excludePatterns,
    );

    for (final file in filesToScan) {
      final relPath = p.relative(file.path, from: rootPath).replaceAll('\\', '/');

      // Check if file matches file patterns
      final matchesFile = filePatterns.any((p) => p.hasMatch(relPath));
      if (!matchesFile) continue;

      // Check if file matches exclude patterns
      final matchesExclude = excludePatterns.any((p) => p.hasMatch(relPath));
      if (matchesExclude) continue;

      // Scan file content
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          for (final sub in substrings) {
            if (lines[i].contains(sub)) {
              errors.add(
                '$relPath:${i + 1} — $message (found forbidden substring: "$sub")',
              );
            }
          }
        }
      } catch (_) {
        // Skip binary or unreadable files gracefully
      }
    }

    return errors;
  }

  Future<void> _findFilesRecursive(
    Directory dir,
    String rootPath,
    List<File> filesList,
    Set<String> ignoreDirNames,
    List<RegExp> excludePatterns,
  ) async {
    try {
      final entities = await dir.list(recursive: false, followLinks: false).toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          if (ignoreDirNames.contains(name)) {
            continue;
          }
          final relPath = p.relative(entity.path, from: rootPath).replaceAll('\\', '/');
          final matchesExclude = excludePatterns.any((p) => p.hasMatch(relPath) || p.hasMatch('$relPath/'));
          if (matchesExclude) {
            continue;
          }
          await _findFilesRecursive(entity, rootPath, filesList, ignoreDirNames, excludePatterns);
        } else if (entity is File) {
          filesList.add(entity);
        }
      }
    } catch (_) {
      // Ignore directory access errors gracefully
    }
  }
}

class StewardConfig {
  StewardConfig({
    this.archetype,
    this.preferredRunner,
    this.validators = const [],
    this.harnessName,
    this.harnessDescription,
    this.pipelines = const {},
    this.docs = const {},
    this.governance = const {},
    this.branding = const {},
  });

  final String? archetype;
  final String? preferredRunner;
  final List<CustomValidator> validators;
  final String? harnessName;
  final String? harnessDescription;
  final Map<String, dynamic> pipelines;
  final Map<String, String> docs;
  final Map<String, dynamic> governance;
  final Map<String, dynamic> branding;

  static Future<StewardConfig> load(String rootPath) async {
    var file = File(p.join(rootPath, 'steward.yaml'));
    if (!file.existsSync()) {
      file = File(p.join(rootPath, 'steward.yml'));
      if (!file.existsSync()) {
        return StewardConfig();
      }
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      final data = _yamlToDart(yaml);

      if (data is! Map) return StewardConfig();

      final archetype = data['archetype'] as String?;
      final preferredRunner = data['preferredRunner'] as String?;
      final validatorsJson = data['validators'] as List?;

      final validators = <CustomValidator>[];
      if (validatorsJson != null) {
        for (final item in validatorsJson) {
          if (item is Map) {
            final v = CustomValidator.fromMap(Map<String, dynamic>.from(item));
            if (v != null) {
              validators.add(v);
            }
          }
        }
      }

      final harnessMap = data['harness'] as Map?;
      final harnessName = harnessMap?['name'] as String?;
      final harnessDescription = harnessMap?['description'] as String?;
      final pipelinesMap = data['pipelines'] as Map? ?? const {};
      final docsMap = data['docs'] as Map? ?? const {};
      final docs = <String, String>{};
      docsMap.forEach((key, value) {
        docs[key.toString()] = value.toString();
      });

      final governanceMap = data['governance'] as Map? ?? const {};
      final brandingMap = data['branding'] as Map? ?? const {};

      return StewardConfig(
        archetype: archetype,
        preferredRunner: preferredRunner,
        validators: validators,
        harnessName: harnessName,
        harnessDescription: harnessDescription,
        pipelines: Map<String, dynamic>.from(pipelinesMap),
        docs: docs,
        governance: Map<String, dynamic>.from(governanceMap),
        branding: Map<String, dynamic>.from(brandingMap),
      );
    } catch (_) {
      return StewardConfig();
    }
  }
}

dynamic _yamlToDart(dynamic node) {
  if (node is YamlMap) {
    return node.map((key, value) => MapEntry(key.toString(), _yamlToDart(value)));
  } else if (node is YamlList) {
    return node.map(_yamlToDart).toList();
  }
  return node;
}
