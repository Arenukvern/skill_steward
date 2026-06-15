import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';
import '../validation/validation.dart'
    show
        ValidationGroupResult,
        ValidationReport,
        validateAllSkills,
        validateEvidence,
        validateLocalSkills,
        validateRepoContract,
        validateSkillRegistry,
        validateSkillsDirectory;

/// Runs skill validation using the Dart implementation (post hardcut from Node).
class ValidateCommand extends Command<void> {
  ValidateCommand() {
    argParser
      ..addFlag('json', help: 'Output results as JSON.')
      ..addFlag(
        'local',
        help: 'Validate local .agents/skills/ directory against skills.json.',
      );
    addSubcommand(_ValidateSkillsCommand());
    addSubcommand(_ValidateRegistryCommand());
    addSubcommand(_ValidateRepoContractCommand());
    addSubcommand(_ValidateEvidenceCommand());
    addSubcommand(_ValidateAllCommand());
  }

  @override
  final name = 'validate';

  @override
  final description = 'Validate skills, registry, repo contract, and evidence.';

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

    _writeValidationReport(report, asJson);

    exitCode = report.ok ? 0 : 1;
  }
}

class _ValidateSkillsCommand extends Command<void> {
  _ValidateSkillsCommand() {
    argParser.addFlag('json', help: 'Output results as JSON.');
  }

  @override
  final name = 'skills';

  @override
  final description = 'Validate installable skill directory structure.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final report = await validateSkillsDirectory('$root/skills');
    _writeValidationReport(report, argResults!['json'] as bool);
    exitCode = report.ok ? 0 : 1;
  }
}

class _ValidateRegistryCommand extends Command<void> {
  _ValidateRegistryCommand() {
    argParser.addFlag('json', help: 'Output results as JSON.');
  }

  @override
  final name = 'registry';

  @override
  final description = 'Validate skills.sh.json against skill directories.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final report = await validateSkillRegistry('$root/skills');
    _writeValidationReport(report, argResults!['json'] as bool);
    exitCode = report.ok ? 0 : 1;
  }
}

class _ValidateRepoContractCommand extends Command<void> {
  _ValidateRepoContractCommand() {
    argParser.addFlag('json', help: 'Output results as JSON.');
  }

  @override
  final name = 'repo-contract';

  @override
  final description = 'Validate repo contract, plans, plugins, and validators.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final report = await validateRepoContract(root);
    _writeValidationReport(report, argResults!['json'] as bool);
    exitCode = report.ok ? 0 : 1;
  }
}

class _ValidateEvidenceCommand extends Command<void> {
  _ValidateEvidenceCommand() {
    argParser.addFlag('json', help: 'Output results as JSON.');
  }

  @override
  final name = 'evidence';

  @override
  final description = 'Validate committed adoption-run evidence.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final report = await validateEvidence(root);
    _writeValidationReport(report, argResults!['json'] as bool);
    exitCode = report.ok ? 0 : 1;
  }
}

class _ValidateAllCommand extends Command<void> {
  _ValidateAllCommand() {
    argParser
      ..addFlag('json', help: 'Output results as JSON.')
      ..addFlag(
        'local',
        help: 'Validate local .agents/skills/ directory against skills.json.',
      );
  }

  @override
  final name = 'all';

  @override
  final description = 'Validate all validation lanes.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(Directory.current);
    final isLocal = argResults!['local'] as bool;
    final report = isLocal
        ? await validateLocalSkills(root)
        : await validateAllSkills('$root/skills');
    _writeValidationReport(report, argResults!['json'] as bool);
    exitCode = report.ok ? 0 : 1;
  }
}

void _writeValidationReport(final ValidationReport report, final bool asJson) {
  if (asJson) {
    final json = const JsonEncoder.withIndent('  ').convert(report.toJson());
    stdout.writeln(json);
    return;
  }

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

  if (report.groups.isNotEmpty) {
    _writeGroupDiagnostics(report.groups);
  } else {
    for (final w in report.registryWarnings) {
      stdout.writeln('warn: $w');
    }
  }

  stdout.writeln();
  final issueCount = _issueCount(report);
  stdout.writeln(
    issueCount == 0
        ? 'Validated ${report.skills.length} skill(s).'
        : '$issueCount error(s)/warning(s) found during validation.',
  );
}

void _writeGroupDiagnostics(final Map<String, ValidationGroupResult> groups) {
  for (final entry in groups.entries) {
    final group = entry.value;
    for (final error in group.errors) {
      stdout.writeln('error[${entry.key}]: $error');
    }
    for (final warning in group.warnings) {
      stdout.writeln('warn[${entry.key}]: $warning');
    }
  }
}

int _issueCount(final ValidationReport report) {
  if (report.groups.isEmpty) {
    return report.failed.length + report.registryWarnings.length;
  }
  final groupIssues = report.groups.values.fold<int>(
    0,
    (final total, final group) =>
        total + group.errors.length + group.warnings.length,
  );
  return report.failed.length + groupIssues;
}
