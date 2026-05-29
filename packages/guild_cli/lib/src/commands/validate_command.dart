import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';

/// Runs skill validation (Node validator today; Dart-native later).
class ValidateCommand extends Command<void> {
  @override
  final name = 'validate';

  @override
  final description =
      'Validate all skills under skills/ (delegates to npm run validate).';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final npm = await _resolveNpm();
    if (npm == null) {
      stderr.writeln('guild validate: npm not found on PATH.');
      stderr.writeln('Install Node 18+ or run: npm run validate');
      exit(1);
    }

    final result = await Process.start(
      npm,
      ['run', 'validate'],
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
