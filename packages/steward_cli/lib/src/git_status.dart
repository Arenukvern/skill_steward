import 'dart:io';

class GitPathStatus {
  const GitPathStatus({required this.code, required this.clean});

  final String code;
  final bool clean;
}

class GitStatusSnapshot {
  const GitStatusSnapshot({
    required this.commit,
    required this.dirty,
    required this.dirtyPaths,
    required this.entries,
    required this.available,
    required this.diagnostics,
  });

  final String? commit;
  final bool? dirty;
  final List<String> dirtyPaths;
  final List<String> entries;
  final bool available;
  final List<String> diagnostics;
}

Future<GitPathStatus> gitPathStatus(
  final String root,
  final String path,
) async {
  final result = await Process.run('git', [
    '--no-optional-locks',
    'status',
    '--porcelain=v1',
    '-z',
    '--untracked-files=normal',
    '--',
    path,
  ], workingDirectory: root);
  if (result.exitCode != 0) {
    return const GitPathStatus(code: 'git_error', clean: false);
  }
  final entries = _porcelainZEntries(result.stdout.toString());
  if (entries.isEmpty) {
    return const GitPathStatus(code: 'clean', clean: true);
  }
  return GitPathStatus(code: entries.first.status, clean: false);
}

Future<GitStatusSnapshot> gitStatusSnapshot(final String root) async {
  final status = await Process.run('git', [
    '--no-optional-locks',
    'status',
    '--porcelain=v1',
    '-z',
    '--untracked-files=normal',
  ], workingDirectory: root);
  if (status.exitCode != 0) {
    return const GitStatusSnapshot(
      commit: null,
      dirty: null,
      dirtyPaths: [],
      entries: [],
      available: false,
      diagnostics: ['Not inside a git worktree.'],
    );
  }

  final shortStatus = await Process.run('git', [
    '--no-optional-locks',
    'status',
    '--short',
    '--untracked-files=normal',
  ], workingDirectory: root);
  final head = await Process.run('git', [
    'rev-parse',
    'HEAD',
  ], workingDirectory: root);

  final entries = _porcelainZEntries(status.stdout.toString());
  final shortEntries = shortStatus.exitCode == 0
      ? shortStatus.stdout
            .toString()
            .split('\n')
            .where((final line) => line.trim().isNotEmpty)
            .toList()
      : entries.map((final entry) => '${entry.status} ${entry.path}').toList();

  return GitStatusSnapshot(
    commit: head.exitCode == 0 ? head.stdout.toString().trim() : null,
    dirty: entries.isNotEmpty,
    dirtyPaths: entries.map((final entry) => entry.path).toList(),
    entries: shortEntries,
    available: true,
    diagnostics: const [],
  );
}

List<_PorcelainEntry> _porcelainZEntries(final String porcelain) {
  final fields = porcelain
      .split('\x00')
      .where((final field) => field.isNotEmpty)
      .toList();
  final entries = <_PorcelainEntry>[];
  for (var index = 0; index < fields.length; index++) {
    final field = fields[index];
    if (field.length < 4) {
      continue;
    }
    final status = field.substring(0, 2).trim();
    final path = field.substring(3);
    if (path.isEmpty) {
      continue;
    }
    entries.add(_PorcelainEntry(status: status, path: path));
    if (status.startsWith('R') || status.startsWith('C')) {
      index++;
    }
  }
  return entries;
}

class _PorcelainEntry {
  const _PorcelainEntry({required this.status, required this.path});

  final String status;
  final String path;
}
