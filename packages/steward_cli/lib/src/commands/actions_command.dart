import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Groups read-only action discovery commands.
class ActionsCommand extends Command<void> {
  ActionsCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(ActionsListCommand(outputSink, startDirectory));
  }

  @override
  final name = 'actions';

  @override
  final description = 'Discover typed Steward actions without running them.';
}

class ActionsListCommand extends Command<void> {
  ActionsListCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'list';

  @override
  final description = 'List typed Steward actions.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await StewardConfig.loadChecked(root);
    final actions = result.config.typedActions;
    final payload = {
      'schema_version': 'steward.actions.v1',
      'root': root,
      'config_valid': result.ok,
      'diagnostics': result.diagnostics
          .map((final diagnostic) => diagnostic.toJson())
          .toList(),
      'actions': actions.map((final action) => action.summaryJson()).toList(),
    };

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    for (final action in actions) {
      sink.writeln(
        '${action.id} [${action.safetyClass}/${action.defaultPolicy}] '
        '${action.desc}',
      );
    }
  }
}
