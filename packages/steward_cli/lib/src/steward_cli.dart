import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/adopt_command.dart';
import 'commands/brand_check_command.dart';
import 'commands/bundle_command.dart';
import 'commands/eval_command.dart';
import 'commands/install_command.dart';
import 'commands/list_command.dart';
import 'commands/map_command.dart';
import 'commands/mcp_command.dart';
import 'commands/uninstall_command.dart';
import 'commands/update_command.dart';
import 'commands/validate_command.dart';
import 'repo_root.dart';

/// Entry point for the `steward` meta harness CLI.
class StewardCli {

  StewardCli() {
    _runner =
        CommandRunner<void>(
            'steward',
            'Skill Steward meta harness — validate, eval, and list skills.',
          )
          ..addCommand(ValidateCommand())
          ..addCommand(EvalCommand())
          ..addCommand(ListCommand())
          ..addCommand(InstallCommand())
          ..addCommand(UpdateCommand())
          ..addCommand(AdoptCommand())
          ..addCommand(UninstallCommand())
          ..addCommand(MapCommand())
          ..addCommand(BrandCheckCommand())
          ..addCommand(McpCommand())
          ..addCommand(BundleCommand());
  }
  late final CommandRunner<void> _runner;

  /// Runs [args] and exits with the command status code.
  Future<void> run(final List<String> args) async {
    final useJson = args.contains('--json');
    try {
      await _runner.run(args);
    } on UsageException catch (e) {
      if (useJson) {
        stdout.writeln(
          '{"error": "${e.message.replaceAll('"', r'\"')}", "type": "UsageException"}',
        );
      } else {
        stderr
          ..writeln(e)
          ..writeln(_runner.usage);
      }
      exit(64);
    } catch (e, st) {
      if (useJson) {
        stdout.writeln(
          '{"error": "${e.toString().replaceAll('"', r'\"')}", "type": "Exception"}',
        );
      } else {
        stderr
          ..writeln('Fatal Error: $e')
          ..writeln(st);
      }
      exit(1);
    }
  }
}

/// Repository root containing `skills/` and `skills.sh.json`.
String repoRootFromCwd() => findRepoRoot(Directory.current);
