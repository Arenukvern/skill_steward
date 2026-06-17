import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../action_runner.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Groups single-action inspection and execution commands.
class ActionCommand extends Command<void> {
  ActionCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(ActionInspectCommand(outputSink, startDirectory));
    addSubcommand(ActionRunCommand(outputSink, startDirectory));
  }

  @override
  final name = 'action';

  @override
  final description = 'Inspect or run one typed Steward action.';
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

class ActionRunCommand extends Command<void> {
  ActionRunCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'run';

  @override
  final description = 'Run one auto-approved typed Steward action by id.';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.length != 1) {
      throw UsageException('Usage: steward action run <id>', usage);
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

    final diagnostics = result.diagnostics
        .map((final diagnostic) => diagnostic.toJson())
        .toList();
    Map<String, dynamic>? execution;
    final violations = actionRunPolicyViolations(action);
    final status = result.ok
        ? violations.isEmpty
              ? null
              : 'rejected'
        : 'blocked_invalid_config';

    if (result.ok && violations.isEmpty) {
      execution = await runStewardAction(root, action);
    }

    final payload = {
      'schema_version': 'steward.action-run.v1',
      'root': root,
      'config_valid': result.ok,
      'diagnostics': diagnostics,
      'policy': actionRunPolicyJson(),
      'action': action.summaryJson(),
      'status': execution?['status'] ?? status,
      'rejections': violations
          .map(
            (final reason) => {
              'action_id': actionId,
              'reason_code': 'run_policy_violation',
              'reason': reason,
              'inspect_ref': 'steward action inspect $actionId --json',
            },
          )
          .toList(),
      'execution': execution,
    };

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    sink
      ..writeln('Steward action run')
      ..writeln('- action: $actionId')
      ..writeln('- status: ${payload['status']}');
    if (violations.isNotEmpty) {
      for (final violation in violations) {
        sink.writeln('- rejected: $violation');
      }
      return;
    }
    if (execution != null) {
      sink
        ..writeln('- exit: ${execution['exit_code']}')
        ..writeln('- duration_ms: ${execution['duration_ms']}');
    }
  }
}
