import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';

/// Skill directory names this repository has retired. Installed copies are
/// prune candidates even when their SKILL.md frontmatter lacks steward
/// metadata, because older generations shipped without an author field.
const List<String> retiredSkillNames = [
  'docs-refresh',
  'docs-refresh-lifecycle',
  'mcp-harness-repo-maintainer',
  'mixture-of-experts',
  'plugin-marketplace-setup',
  'skill-eval-improve',
  'skill-source-citations',
  'steward-continuity-boundary-lifecycle',
  'storytelling-ethics-lifecycle',
  'vision-alignment-foresight',
];

const String stewardSyncSchemaVersion = 'steward.sync.v1';

class _StaleEntry {
  _StaleEntry(this.name, this.type, this.entity);

  final String name;
  final String type;
  final FileSystemEntity entity;
  bool pruned = false;

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'pruned': pruned,
  };
}

class _ScopeReport {
  _ScopeReport(this.path, this.kind) : stale = [], unrecognized = [], missing = [];

  final String path;
  final String kind;
  final List<_StaleEntry> stale;

  /// Steward-authored skill names this manifest does not know. Reported for
  /// review; never pruned, because other repos may legitimately share the
  /// author marker.
  final List<String> unrecognized;
  final List<String> missing;
  int foreign = 0;

  Map<String, dynamic> toJson() => {
    'path': path,
    'kind': kind,
    'stale': [for (final entry in stale) entry.toJson()],
    'unrecognized': unrecognized,
    'missing': missing,
    'foreign': foreign,
  };
}

/// Diffs installed skill copies against the `skills.sh.json` marketplace
/// manifest and prunes steward-owned skills that are no longer in it.
///
/// Only skills this repository actually shipped are prunable: retired names
/// ([retiredSkillNames]) always, and the `author: skill-steward` marker never
/// on its own — other repos share that author, so marker-only matches are
/// reported as `unrecognized` for review instead. Report-only by default;
/// pass `--prune` to delete. Exits 1 when stale skills exist and `--prune`
/// was not requested.
class SyncCommand extends Command<void> {
  SyncCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
    final Directory? globalBaseDirectory,
  ]) : _outputSink = outputSink,
       _startDirectory = startDirectory,
       _globalBase = globalBaseDirectory {
    argParser
      ..addFlag(
        'prune',
        negatable: false,
        help: 'Delete stale steward-owned skills. Default: report only.',
      )
      ..addFlag(
        'global',
        abbr: 'g',
        negatable: false,
        help: 'Also scan agent skill directories under the user home.',
      )
      ..addMultiOption(
        'path',
        help: 'Additional skill directory to scan (repeatable).',
      )
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.');
  }

  final StringSink? _outputSink;
  final Directory? _startDirectory;
  final Directory? _globalBase;

  @override
  final name = 'sync';

  @override
  final description =
      'Maintainer. Do not start here. Diff installed skill copies against '
      'skills.sh.json and prune retired or unknown steward-owned skills.';

  StringSink get _out => _outputSink ?? stdout;

  @override
  Future<void> run() async {
    final pruneRequested = argResults!['prune'] as bool;
    final scanGlobal = argResults!['global'] as bool;
    final extraPaths = argResults!['path'] as List<String>;
    final useJson = argResults!['json'] as bool;
    final start = _startDirectory ?? Directory.current;
    final root = findRepoRoot(start);

    final manifestFile = File(p.join(root, 'skills.sh.json'));
    if (!manifestFile.existsSync()) {
      stderr.writeln(
        'Error: skills.sh.json not found under $root. '
        'steward sync diffs installed copies against the skill_steward '
        'marketplace manifest.',
      );
      exitCode = 64;
      return;
    }

    final List<String> manifest;
    try {
      final data =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      manifest = [
        for (final entry in (data['skills'] as List? ?? <dynamic>[]))
          entry as String,
      ];
    } on Object catch (e) {
      stderr.writeln('Error: failed to parse skills.sh.json: $e');
      exitCode = 64;
      return;
    }
    final canonical = manifest.toSet();
    final ownedNames = canonical.union(retiredSkillNames.toSet());

    final reports = <_ScopeReport>[];
    final seen = <String>{};
    void addScope(final String dirPath, final String kind) {
      final normalized = p.normalize(dirPath);
      if (!seen.add(normalized)) {
        return;
      }
      final dir = Directory(normalized);
      if (!dir.existsSync()) {
        if (kind == 'explicit') {
          stderr.writeln(
            'Warning: --path $normalized does not exist, skipped.',
          );
        }
        return;
      }
      final report = _ScopeReport(normalized, kind);
      _scanScope(dir, canonical, ownedNames, report);
      reports.add(report);
    }

    for (final candidate in _scopeCandidates()) {
      addScope(p.join(root, candidate), 'project');
    }
    if (scanGlobal) {
      final home = _globalBase?.path ?? _homeDirectory();
      if (home == null) {
        stderr.writeln('Warning: could not resolve the user home directory.');
      } else {
        for (final candidate in _scopeCandidates()) {
          addScope(p.join(home, candidate), 'global');
        }
      }
    }
    for (final extra in extraPaths) {
      addScope(
        p.isAbsolute(extra) ? extra : p.join(Directory.current.path, extra),
        'explicit',
      );
    }

    final staleTotal = reports.fold<int>(
      0,
      (final total, final scope) => total + scope.stale.length,
    );
    final failures = <String>[];
    if (pruneRequested) {
      for (final scope in reports) {
        for (final entry in scope.stale) {
          try {
            entry.entity.deleteSync(recursive: true);
            entry.pruned = true;
          } on Object catch (e) {
            failures.add('${entry.entity.path}: $e');
          }
        }
      }
    }
    final prunedTotal = pruneRequested ? staleTotal - failures.length : 0;

    if (useJson) {
      _out.writeln(
        jsonEncode({
          'schema_version': stewardSyncSchemaVersion,
          'root': root,
          'manifest': manifest,
          'prune': pruneRequested,
          'scopes': [for (final scope in reports) scope.toJson()],
          'stale_total': staleTotal,
          'pruned_total': prunedTotal,
          'failures': failures,
        }),
      );
    } else {
      _out.writeln(
        'Manifest: ${manifest.length} skill(s); scanned ${reports.length} scope(s).',
      );
      for (final scope in reports) {
        _out.writeln('${scope.path} [${scope.kind}]');
        for (final entry in scope.stale) {
          final state = pruneRequested
              ? (entry.pruned ? 'pruned' : 'DELETE FAILED')
              : 'stale';
          _out.writeln('  $state: ${entry.name} (${entry.type})');
        }
        if (scope.unrecognized.isNotEmpty) {
          _out.writeln(
            '  steward-authored, unknown to this manifest (kept): '
            '${scope.unrecognized.join(', ')}',
          );
        }
        if (scope.missing.isNotEmpty) {
          _out.writeln(
            '  manifest skills not installed here: ${scope.missing.join(', ')}',
          );
        }
        if (scope.foreign > 0) {
          _out.writeln('  foreign skills kept: ${scope.foreign}');
        }
      }
      if (!pruneRequested && staleTotal > 0) {
        _out.writeln('Run with --prune to delete $staleTotal stale skill(s).');
      }
      for (final failure in failures) {
        stderr.writeln('Failed to prune: $failure');
      }
    }

    if (pruneRequested) {
      exitCode = failures.isEmpty ? 0 : 1;
    } else {
      exitCode = staleTotal > 0 ? 1 : 0;
    }
  }

  void _scanScope(
    final Directory dir,
    final Set<String> canonical,
    final Set<String> ownedNames,
    final _ScopeReport report,
  ) {
    for (final entity in dir.listSync(followLinks: false)) {
      final name = p.basename(entity.path);
      if (canonical.contains(name)) {
        continue;
      }
      if (ownedNames.contains(name)) {
        report.stale.add(
          _StaleEntry(name, entity is Link ? 'symlink' : 'directory', entity),
        );
        continue;
      }
      if (_hasStewardAuthor(entity)) {
        report.unrecognized.add(name);
        continue;
      }
      report.foreign += 1;
    }
    for (final name in canonical) {
      final type = FileSystemEntity.typeSync(p.join(dir.path, name));
      if (type == FileSystemEntityType.notFound) {
        report.missing.add(name);
      }
    }
  }

  /// True when the entry resolves to a directory whose SKILL.md frontmatter
  /// carries the steward author marker. Dangling symlinks return false; the
  /// retired-name rule already covers the ones worth pruning.
  bool _hasStewardAuthor(final FileSystemEntity entity) {
    String? dirPath;
    if (entity is Link) {
      try {
        final target = entity.targetSync();
        final resolved = p.isAbsolute(target)
            ? target
            : p.normalize(p.join(p.dirname(entity.path), target));
        if (!Directory(resolved).existsSync()) {
          return false;
        }
        dirPath = resolved;
      } on FileSystemException {
        return false;
      }
    } else if (entity is Directory) {
      dirPath = entity.path;
    }
    if (dirPath == null) {
      return false;
    }
    final skillFile = File(p.join(dirPath, 'SKILL.md'));
    if (!skillFile.existsSync()) {
      return false;
    }
    return RegExp(
      r'^\s*author:\s*"?skill-steward"?\s*$',
      multiLine: true,
    ).hasMatch(_frontmatterBlock(skillFile));
  }

  String _frontmatterBlock(final File skillFile) {
    final lines = skillFile.readAsStringSync().split('\n');
    final buffer = StringBuffer();
    var inside = false;
    for (final line in lines) {
      if (line.trim() == '---') {
        if (inside) {
          break;
        }
        inside = true;
        continue;
      }
      if (inside) {
        buffer.writeln(line);
      }
    }
    return buffer.toString();
  }

  List<String> _scopeCandidates() => const [
    '.agents/skills',
    '.cursor/skills',
    '.claude/skills',
    '.codex/skills',
  ];

  String? _homeDirectory() =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
}
