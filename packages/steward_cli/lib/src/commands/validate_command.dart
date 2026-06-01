import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';
import '../validation/validation.dart' show validateAllSkills, validateLocalSkills, ValidationReport;

/// Runs skill validation using the Dart implementation (post hardcut from Node).
class ValidateCommand extends Command<void> {
  ValidateCommand() {
    argParser
      ..addFlag(
        'json',
        help: 'Output results as JSON.',
      )
      ..addFlag(
        'local',
        help: 'Validate local .agents/skills/ directory against skills.json.',
      );
  }

  @override
  final name = 'validate';

  @override
  final description = 'Validate all skills.';

  @override
  Future<void> run() async {
    final asJson = argResults!['json'] as bool;
    final isLocal = argResults!['local'] as bool;

    final root = findRepoRoot(Directory.current);

    final ValidationReport report;
    if (isLocal) {
      report = await validateLocalSkills(root);
    } else {
      final skillsDir = '$root/skills';
      report = await validateAllSkills(skillsDir);
    }

    if (asJson) {
      final json = const JsonEncoder.withIndent('  ').convert(report.toJson());
      stdout.writeln(json);
    } else {
      for (final r in report.skills) {
        final icon = r.isValid ? '✓' : '✗';
        stdout.writeln('$icon ${r.dirName}');
        for (final e in r.errors) {
          stdout.writeln('    error: $e');
        }
        for (final w in r.warnings) {
          stdout.writeln('    warn:  $w');
        }
      }
      for (final w in report.registryWarnings) {
        stdout.writeln('warn: $w');
      }
      stdout.writeln();
      final failed = report.failed.length;
      stdout.writeln(
        failed == 0 && report.registryWarnings.isEmpty
            ? 'Validated ${report.skills.length} skill(s).'
            : '${failed + report.registryWarnings.length} error(s)/warning(s) found during validation.',
      );
    }

    exit(report.ok ? 0 : 1);
  }
}

