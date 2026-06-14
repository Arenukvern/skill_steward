import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Groups read-only single-action inspection commands.
class ActionCommand extends Command<void> {
  ActionCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(ActionInspectCommand(outputSink, startDirectory));
  }

  @override
  final name = 'action';

  @override
  final description = 'Inspect one typed Steward action without running it.';
}

class ActionInspectCommand extends Command<void> {
  ActionInspectCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'inspect';

  @override
  final description = 'Inspect one typed Steward action by id.';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.length != 1) {
      throw UsageException('Usage: steward action inspect <id>', usage);
    }

    final actionId = rest.single;
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await StewardConfig.loadChecked(root);
    StewardAction? action;
    for (final candidate in result.config.typedActions) {
      if (candidate.id == actionId) {
        action = candidate;
        break;
      }
    }
    if (action == null) {
      throw UsageException('Unknown Steward action: $actionId', usage);
    }

    final payload = {
      'schema_version': 'steward.action.v1',
      'root': root,
      'config_valid': result.ok,
      'diagnostics': result.diagnostics
          .map((final diagnostic) => diagnostic.toJson())
          .toList(),
      'action': action.toJson(),
    };

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    sink
      ..writeln('${action.id}: ${action.desc}')
      ..writeln('- safety: ${action.safetyClass}/${action.defaultPolicy}')
      ..writeln('- requires confirmation: ${action.requiresConfirmation}');
  }
}
