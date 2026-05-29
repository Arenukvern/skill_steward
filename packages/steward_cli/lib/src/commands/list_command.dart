import 'dart:io';

import 'package:args/command_runner.dart';

import '../package_manager.dart';
import '../repo_root.dart';

/// Lists installable skills (delegates to pnpm/npm run list).
class ListCommand extends Command<void> {
  @override
  final name = 'list';

  @override
  final description = 'List skills in skills/ (delegates to pnpm/npm run list).';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final runner = await PackageRunner.resolve();
    if (runner == null) {
      stderr.writeln('steward list: pnpm or npm not found on PATH.');
      stderr.writeln('Install Node 18+ and pnpm, or run: pnpm run list');
      exit(1);
    }

    final result = await Process.start(
      runner.executable,
      runner.runArgs('list'),
      workingDirectory: root,
      mode: ProcessStartMode.inheritStdio,
    );
    exit(await result.exitCode);
  }
}
