import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/action_candidate_command.dart';
import 'commands/action_command.dart';
import 'commands/actions_command.dart';
import 'commands/adopt_command.dart';
import 'commands/benchmark_command.dart';
import 'commands/blocked_command.dart';
import 'commands/brand_check_command.dart';
import 'commands/bundle_command.dart';
import 'commands/claim_command.dart';
import 'commands/diagnose_command.dart';
import 'commands/doctor_command.dart';
import 'commands/ecology_command.dart';
import 'commands/eval_command.dart';
import 'commands/install_command.dart';
import 'commands/list_command.dart';
import 'commands/map_command.dart';
import 'commands/mcp_command.dart';
import 'commands/observe_command.dart';
import 'commands/probe_command.dart';
import 'commands/protocol_command.dart';
import 'commands/schema_command.dart';
import 'commands/uninstall_command.dart';
import 'commands/unknown_case_command.dart';
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
          ..addCommand(DoctorCommand())
          ..addCommand(EcologyCommand())
          ..addCommand(ActionsCommand())
          ..addCommand(ActionCommand())
          ..addCommand(ActionCandidateCommand())
          ..addCommand(ProbeCommand())
          ..addCommand(SchemaCommand())
          ..addCommand(ProtocolCommand())
          ..addCommand(ClaimCommand())
          ..addCommand(BlockedCommand())
          ..addCommand(ObserveCommand())
          ..addCommand(UnknownCaseCommand())
          ..addCommand(DiagnoseCommand())
          ..addCommand(BenchmarkCommand())
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
          jsonEncode({'error': e.message, 'type': 'UsageException'}),
        );
      } else {
        stderr
          ..writeln(e)
          ..writeln(_runner.usage);
      }
      exit(64);
    } on Object catch (e, st) {
      if (useJson) {
        stdout.writeln(
          jsonEncode({'error': e.toString(), 'type': 'Exception'}),
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
