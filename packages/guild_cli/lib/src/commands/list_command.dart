import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';

/// Lists installable skills (delegates to npm run list).
class ListCommand extends Command<void> {
  @override
  final name = 'list';

  @override
  final description = 'List skills in skills/ (delegates to npm run list).';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final npm = await _resolveNpm();
    if (npm == null) {
      stderr.writeln('guild list: npm not found on PATH.');
      stderr.writeln('Install Node 18+ or run: npm run list');
      exit(1);
    }

    final result = await Process.start(
      npm,
      ['run', 'list'],
      workingDirectory: root,
      mode: ProcessStartMode.inheritStdio,
    );
    exit(await result.exitCode);
  }

  Future<String?> _resolveNpm() async {
    final which = await Process.run('which', ['npm']);
    if (which.exitCode == 0) {
      return (which.stdout as String).trim().split('\n').first;
    }
    return null;
  }
}
