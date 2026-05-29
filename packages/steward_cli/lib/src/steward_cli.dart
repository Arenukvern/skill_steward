import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/list_command.dart';
import 'commands/validate_command.dart';
import 'repo_root.dart';

/// Entry point for the `steward` meta harness CLI.
class StewardCli {
  /// Runs [args] and exits with the command status code.
  Future<void> run(final List<String> args) async {
    final runner = CommandRunner<void>(
      'steward',
      'Skill Steward meta harness — validate and list skills.',
    )
      ..addCommand(ValidateCommand())
      ..addCommand(ListCommand());

    try {
      await runner.run(args);
    } on UsageException catch (e) {
      stderr
        ..writeln(e)
        ..writeln(runner.usage);
      exit(64);
    }
  }
}

/// Repository root containing `skills/` and `skills.sh.json`.
String repoRootFromCwd() => findRepoRoot(Directory.current);
