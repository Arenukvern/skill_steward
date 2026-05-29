import 'dart:io';

import 'package:args/command_runner.dart';

import '../package_manager.dart';
import '../repo_root.dart';

/// Runs skill validation (Node validator today; Dart-native later).
class ValidateCommand extends Command<void> {
  @override
  final name = 'validate';

  @override
  final description =
      'Validate all skills under skills/ (delegates to pnpm/npm run validate).';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final runner = await PackageRunner.resolve();
    if (runner == null) {
      stderr.writeln('steward validate: pnpm or npm not found on PATH.');
      stderr.writeln('Install Node 18+ and pnpm, or run: pnpm run validate');
      exit(1);
    }

    final result = await Process.start(
      runner.executable,
      runner.runArgs('validate'),
      workingDirectory: root,
      mode: ProcessStartMode.inheritStdio,
    );
    exit(await result.exitCode);
  }
}
