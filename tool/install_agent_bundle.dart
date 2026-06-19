import 'dart:convert';
import 'dart:io';

const productId = 'skill-steward';
const productDisplayName = 'Skill Steward';

const payloadEntries = <String>[
  '.plugin',
  '.codex-plugin',
  '.cursor-plugin',
  '.claude-plugin',
  'skills',
];

void main(final List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _usage();
    return;
  }

  final root = _findRepoRoot(Directory.current);
  final target = _target(args);
  final check = args.contains('--check');
  final verbose = args.contains('--verbose');
  final version = _packageVersion(root);
  final writes = <String>[];

  void run(final String name, final void Function() action) {
    if (target == 'all' || target == name) {
      action();
    }
  }

  run('cursor', () => _writeCursor(root, check, writes));
  run('codex', () => _writeCodex(root, version, check, writes));
  run('claude-code', () => _writeClaudeCode(root, check, writes));
  run('agents-skills', () => _writeAgentsSkills(root, check, writes));

  if (writes.isEmpty) {
    stderr.writeln('No writes planned for target "$target".');
  } else {
    stdout.writeln(
      check
          ? 'Planned ${writes.length} write path(s).'
          : 'Wrote ${writes.length} path(s).',
    );
    if (verbose) {
      for (final path in writes) {
        stdout.writeln('- $path');
      }
    } else {
      stdout.writeln('Re-run with --verbose to list every path.');
    }
  }
}

void _usage() {
  stdout.writeln('''
Usage: dart run tool/install_agent_bundle.dart [target] [--check] [--verbose]

Targets:
  all            Install every local agent bundle target (default)
  cursor         Copy repo plugin payload to .cursor/plugins/local/skill-steward
  codex          Copy repo plugin payload to .codex/plugins/cache/local/skill-steward/local and update .agents/plugins/marketplace.json
  claude-code    Copy skills to .claude/skills/skill-steward/
  agents-skills  Copy skills to .agents/skills/

This is a repo-local helper. It does not publish to public marketplaces.''');
}

String _target(final List<String> args) {
  final positional = args.where((final arg) => !arg.startsWith('-')).toList();
  final target = positional.isEmpty ? 'all' : positional.first;
  const allowed = {'all', 'cursor', 'codex', 'claude-code', 'agents-skills'};
  if (!allowed.contains(target)) {
    throw ArgumentError.value(
      target,
      'target',
      'Expected one of ${allowed.join(", ")}',
    );
  }
  return target;
}

Directory _findRepoRoot(final Directory start) {
  var current = start.absolute;
  while (true) {
    if (File('${current.path}/package.json').existsSync() &&
        Directory('${current.path}/skills').existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find Skill Steward repo root.');
    }
    current = parent;
  }
}

String _packageVersion(final Directory root) {
  final file = File('${root.path}/package.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return data['version'] as String? ?? '0.0.0';
}

void _writeCursor(
  final Directory root,
  final bool check,
  final List<String> writes,
) {
  final destination = Directory(
    '${root.path}/.cursor/plugins/local/$productId',
  );
  _copyBundlePayload(root, destination, check, writes);
}

void _writeCodex(
  final Directory root,
  final String version,
  final bool check,
  final List<String> writes,
) {
  final destination = Directory(
    '${root.path}/.codex/plugins/cache/local/$productId/local',
  );
  _copyBundlePayload(root, destination, check, writes);
  _writeCodexMarketplace(root, destination.path, version, check, writes);
}

void _writeClaudeCode(
  final Directory root,
  final bool check,
  final List<String> writes,
) {
  final skillRoot = Directory('${root.path}/skills');
  final destinationRoot = Directory('${root.path}/.claude/skills/$productId');
  if (!check && destinationRoot.existsSync()) {
    destinationRoot.deleteSync(recursive: true);
  }
  for (final skill in _skillDirs(skillRoot)) {
    final destination = Directory(
      '${destinationRoot.path}/${_basename(skill.path)}',
    );
    _copyDirectory(skill, destination, check, writes);
  }
}

void _writeAgentsSkills(
  final Directory root,
  final bool check,
  final List<String> writes,
) {
  final skillRoot = Directory('${root.path}/skills');
  for (final skill in _skillDirs(skillRoot)) {
    final destination = Directory(
      '${root.path}/.agents/skills/${_basename(skill.path)}',
    );
    if (!check && destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
    _copyDirectory(skill, destination, check, writes);
  }
}

List<Directory> _skillDirs(final Directory skillRoot) {
  final dirs =
      skillRoot
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where((final dir) => File('${dir.path}/SKILL.md').existsSync())
          .toList()
        ..sort((final a, final b) => a.path.compareTo(b.path));
  return dirs;
}

void _copyBundlePayload(
  final Directory root,
  final Directory destination,
  final bool check,
  final List<String> writes,
) {
  if (!check && destination.existsSync()) {
    destination.deleteSync(recursive: true);
  }
  for (final entry in payloadEntries) {
    final source = FileSystemEntity.typeSync('${root.path}/$entry');
    final targetPath = '${destination.path}/$entry';
    switch (source) {
      case FileSystemEntityType.directory:
        _copyDirectory(
          Directory('${root.path}/$entry'),
          Directory(targetPath),
          check,
          writes,
        );
      case FileSystemEntityType.file:
        _copyFile(File('${root.path}/$entry'), File(targetPath), check, writes);
      case _:
        stderr.writeln('Skipping missing optional payload: $entry');
    }
  }
}

void _copyDirectory(
  final Directory source,
  final Directory destination,
  final bool check,
  final List<String> writes,
) {
  if (!source.existsSync()) {
    stderr.writeln('Skipping missing directory: ${source.path}');
    return;
  }
  if (check) {
    writes.add(destination.path);
  } else {
    destination.createSync(recursive: true);
  }
  for (final entity in source.listSync(followLinks: false)) {
    final name = _basename(entity.path);
    if (name == '.DS_Store') {
      continue;
    }
    final targetPath = '${destination.path}/$name';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(targetPath), check, writes);
    } else if (entity is File) {
      _copyFile(entity, File(targetPath), check, writes);
    }
  }
}

void _copyFile(
  final File source,
  final File destination,
  final bool check,
  final List<String> writes,
) {
  writes.add(destination.path);
  if (check) {
    return;
  }
  destination.parent.createSync(recursive: true);
  destination.writeAsBytesSync(source.readAsBytesSync());
}

void _writeCodexMarketplace(
  final Directory root,
  final String sourcePath,
  final String version,
  final bool check,
  final List<String> writes,
) {
  final file = File('${root.path}/.agents/plugins/marketplace.json');
  final marketplace = <String, dynamic>{
    'name': 'local-$productId',
    'interface': {'displayName': productDisplayName},
    'plugins': [
      {
        'name': productId,
        'source': {'source': 'local', 'path': sourcePath},
        'policy': {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'},
        'category': 'Developer Tools',
        'version': version,
      },
    ],
  };
  writes.add(file.path);
  if (check) {
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(marketplace)}\n',
  );
}

String _basename(final String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.lastWhere((final part) => part.isNotEmpty);
}
