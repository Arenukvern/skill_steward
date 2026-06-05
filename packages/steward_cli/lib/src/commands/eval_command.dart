import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/steward_config.dart';

class EvalCommand extends Command<void> {
  EvalCommand() {
    argParser.addOption('name', abbr: 'n', help: 'The name of the eval to run');
  }

  @override
  final name = 'eval';

  @override
  final description = 'Runs a registered verification eval from steward.yaml';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final config = await StewardConfig.load(root);

    final String? evalName = argResults?['name'] as String?;

    if (evalName == null || evalName.isEmpty) {
      print('Available evals:');
      if (config.evals.isEmpty) {
        print('  (None registered in steward.yaml)');
      } else {
        config.evals.forEach((final k, final v) {
          final desc = (v as Map)['desc'] ?? '';
          print('  $k: $desc');
        });
      }
      exit(1);
    }

    if (!config.evals.containsKey(evalName)) {
      print('Error: Eval "$evalName" not found in steward.yaml');
      exit(1);
    }

    final evalData = config.evals[evalName] as Map<String, dynamic>;

    // Evaluate Agent Telemetry (if configured)
    final maxToolCalls = evalData['max_tool_calls'] as int?;
    final telemetryAssertions = evalData['telemetry_assertions'] as List?;

    if (maxToolCalls != null || telemetryAssertions != null) {
      final traceFile =
          config.telemetry['trace_file'] as String? ?? '.steward_trace.json';
      final file = File(p.join(root, traceFile));

      if (!file.existsSync()) {
        print('\n[EVAL FAILED] Telemetry trace file $traceFile not found.');
        exit(1);
      }

      int callCount = 0;
      final parsedLines = <Map<String, dynamic>>[];

      final lines = file.readAsLinesSync();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        callCount++;
        try {
          parsedLines.add(jsonDecode(line) as Map<String, dynamic>);
        } catch (_) {}
      }

      if (maxToolCalls != null) {
        if (callCount > maxToolCalls) {
          print(
            '\n[EVAL FAILED] Agent exceeded max_tool_calls. Expected <= $maxToolCalls, but made $callCount calls.',
          );
          exit(1);
        } else {
          print(
            '[TELEMETRY] Agent completed in $callCount tool calls (Allowed: $maxToolCalls).',
          );
        }
      }

      if (telemetryAssertions != null) {
        for (final assertion in telemetryAssertions) {
          if (assertion is! Map) continue;
          final requiredAction = assertion['action'] as String?;
          final requiredTool = assertion['tool'] as String?;
          final targetName = assertion['target_name'] as String?;

          bool found = false;
          for (final traceItem in parsedLines) {
            // For this naive implementation, we just check if the tool matches
            // and the target_name exists in the arguments map.
            if (traceItem['tool'] == requiredTool) {
              final args = traceItem['arguments'];
              if (args is Map && args['name'] == targetName) {
                found = true;
                break;
              }
            }
          }

          if (!found) {
            print(
              '\n[EVAL FAILED] Telemetry assertion failed. Agent never executed action: $requiredAction, tool: $requiredTool, target: $targetName',
            );
            exit(1);
          } else {
            print(
              '[TELEMETRY] Assertion passed: Agent executed tool $requiredTool on target $targetName.',
            );
          }
        }
      }
    }

    final String? cmd = evalData['verification_cmd'] as String?;
    if (cmd != null) {
      print('Running eval verification cmd...');
      print('\$ $cmd');

      final result = await Process.run('bash', [
        '-c',
        cmd,
      ], workingDirectory: root);

      if (result.stdout.toString().isNotEmpty) {
        print(result.stdout);
      }
      if (result.stderr.toString().isNotEmpty) {
        print(result.stderr);
      }

      if (result.exitCode != 0) {
        print(
          '\n[EVAL FAILED] The verification command returned exit code ${result.exitCode}.',
        );
        exit(result.exitCode);
      }
    }

    print('\n[EVAL PASSED] Evaluation "$evalName" succeeded.');
    exit(0);
  }
}
