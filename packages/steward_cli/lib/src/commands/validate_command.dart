import 'dart:io';

import 'package:args/command_runner.dart';

import '../package_manager.dart';
import '../repo_root.dart';

/// Runs skill validation (Node validator + Tier 1 rule-based evals).
class ValidateCommand extends Command<void> {
  @override
  final name = 'validate';

  @override
  final description =
      'Validate all skills (pnpm/npm run validate + eval for Tier 1).';

  static const _scripts = ['validate', 'eval'];

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final runner = await PackageRunner.resolve();
    if (runner == null) {
      stderr
        ..writeln('steward validate: pnpm or npm not found on PATH.')
        ..writeln('Install Node 18+ and pnpm, or run: pnpm run validate && pnpm run eval');
      exit(1);
    }

    for (final script in _scripts) {
      stdout.writeln('steward validate: pnpm run $script');
      final result = await Process.start(
        runner.executable,
        runner.runArgs(script),
        workingDirectory: root,
        mode: ProcessStartMode.inheritStdio,
      );
      final code = await result.exitCode;
      if (code != 0) {
        stderr.writeln('steward validate: failed at pnpm run $script (exit $code)');
        exit(code);
      }
    }
  }
}
