import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../eval/eval_runner.dart' show evalAllSkills;
import '../repo_root.dart';

/// Runs Tier 1 rule-based skill evals (port of scripts/eval-skill.mjs).
///
/// Supports:
///   --json           Machine-readable JSON output (matches Node shape).
///   --skill NAME     Run evals for a single named skill only.
class EvalCommand extends Command<void> {
  EvalCommand() {
    argParser
      ..addFlag('json', help: 'Output results as JSON.')
      ..addOption(
        'skill',
        help: 'Run evals for a single skill only.',
        valueHelp: 'skill-name',
      );
  }

  @override
  final name = 'eval';

  @override
  final description =
      'Run Tier 1 rule-based skill evals (no LLM judge — see ADR 0011).';

  @override
  Future<void> run() async {
    final asJson = argResults!['json'] as bool;
    final skillFilter = argResults!['skill'] as String?;

    final root = findRepoRoot(Directory.current);
    final skillsDir = '$root/skills';

    final targets = skillFilter != null ? [skillFilter] : null;
    final report = await evalAllSkills(skillsDir, targets: targets);

    if (asJson) {
      final json = const JsonEncoder.withIndent('  ').convert(report.toJson());
      stdout.writeln(json);
    } else {
      final lines = <String>[];
      for (final r in report.results) {
        final status = r.isOk ? 'ok' : 'FAIL';
        lines.add('$status ${r.skillName} (${r.passed}/${r.total} cases)');
        for (final w in r.warnings) {
          lines.add('  warn: $w');
        }
        for (final e in r.errors) {
          lines.add('  error: $e');
        }
      }
      stdout.writeln(lines.join('\n'));
      if (report.ok) {
        stdout.writeln(
          '\nEvaluated ${report.results.length} Tier-1 skill(s). '
          'Rule-based only — see ADR 0011.',
        );
      }
    }

    exit(report.ok ? 0 : 1);
  }
}
