import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../eval/eval.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

void _write([final Object? object = '']) => stdout.writeln(object);

class EvalCommand extends Command<void> {
  EvalCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help:
            'Run a registered telemetry/dogfood eval from steward.yaml. Legacy path; skill evals are the default.',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Emit machine-readable JSON for Tier-1 skill evals.',
      )
      ..addFlag(
        'skill',
        negatable: false,
        help:
            'Run Tier-1 skill evals. This is the default when --name is omitted.',
      );
  }

  @override
  final name = 'eval';

  @override
  final description =
      'Runs Tier-1 skill evals; --name runs a registered steward.yaml eval.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final String? evalName = argResults?['name'] as String?;

    if (evalName == null || evalName.isEmpty) {
      await _runSkillEvals(root);
      return;
    }

    await _runRegisteredEval(root, evalName);
  }

  Future<void> _runSkillEvals(final String root) async {
    final useJson = argResults?['json'] as bool? ?? false;
    final targets = argResults?.rest
        .where((final value) => value.trim().isNotEmpty && value != '--')
        .toList();
    final report = await evalAllSkills(
      p.join(root, 'skills'),
      targets: targets == null || targets.isEmpty ? null : targets,
    );

    if (useJson) {
      _write(jsonEncode(report.toJson()));
    } else {
      _write('Tier-1 skill evals');
      for (final result in report.results) {
        final status = result.isOk ? 'ok' : 'error';
        _write(
          '$status ${result.skillName}: ${result.passed}/${result.total} cases passed',
        );
        for (final warning in result.warnings) {
          _write('  warn: $warning');
        }
        for (final error in result.errors) {
          _write('  error: $error');
        }
      }
    }

    exit(report.ok ? 0 : 1);
  }

  Future<void> _runRegisteredEval(
    final String root,
    final String evalName,
  ) async {
    final config = await StewardConfig.load(root);

    if (config.isV1) {
      _write(
        'Error: registered runtime evals are disabled for schema: steward/v1. Use steward benchmark or steward dogfood for runtime scenarios.',
      );
      exit(1);
    }

    if (!config.evals.containsKey(evalName)) {
      _write('Error: Eval "$evalName" not found in steward.yaml');
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
        _write('\n[EVAL FAILED] Telemetry trace file $traceFile not found.');
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
        } on Object catch (_) {}
      }

      if (maxToolCalls != null) {
        if (callCount > maxToolCalls) {
          _write(
            '\n[EVAL FAILED] Agent exceeded max_tool_calls. Expected <= $maxToolCalls, but made $callCount calls.',
          );
          exit(1);
        } else {
          _write(
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
            _write(
              '\n[EVAL FAILED] Telemetry assertion failed. Agent never executed action: $requiredAction, tool: $requiredTool, target: $targetName',
            );
            exit(1);
          } else {
            _write(
              '[TELEMETRY] Assertion passed: Agent executed tool $requiredTool on target $targetName.',
            );
          }
        }
      }
    }

    final String? cmd = evalData['verification_cmd'] as String?;
    if (cmd != null) {
      _write('Running eval verification cmd...');
      _write('\$ $cmd');

      final result = await Process.run('bash', [
        '-c',
        cmd,
      ], workingDirectory: root);

      if (result.stdout.toString().isNotEmpty) {
        _write(result.stdout);
      }
      if (result.stderr.toString().isNotEmpty) {
        _write(result.stderr);
      }

      if (result.exitCode != 0) {
        _write(
          '\n[EVAL FAILED] The verification command returned exit code ${result.exitCode}.',
        );
        exit(result.exitCode);
      }
    }

    _write('\n[EVAL PASSED] Evaluation "$evalName" succeeded.');
    exit(0);
  }
}
