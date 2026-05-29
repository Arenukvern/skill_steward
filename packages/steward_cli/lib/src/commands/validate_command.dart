import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';
import '../validation/skill_validator.dart' show validateAllSkills;

/// Runs skill validation using the Dart implementation (post hardcut from Node).
class ValidateCommand extends Command<void> {
  @override
  final name = 'validate';

  @override
  final description = 'Validate all skills.';

  ValidateCommand() {
    argParser.addFlag(
      'json',
      help: 'Output results as JSON.',
    );
  }

  @override
  Future<void> run() async {
    final asJson = argResults!['json'] as bool;

    final root = findRepoRoot(Directory.current);
    final skillsDir = '$root/skills';

    final report = await validateAllSkills(skillsDir);

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
      stdout.writeln('');
      final failed = report.failed.length;
      stdout.writeln(
        failed == 0
            ? 'Validated ${report.skills.length} skill(s).'
            : '$failed skill(s) failed validation.',
      );
    }

    exit(report.ok ? 0 : 1);
  }
}
