import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'skill_validator.dart' show validateSingleSkill;
import 'steward_config.dart';
import 'validation_result.dart';

/// Validates repository-local skill registration.
///
/// Ensures all skills declared in `skills.json` are present under `.agents/skills/`
/// and conform to the standards. Emits warnings for undeclared local skills.
Future<ValidationReport> validateLocalSkills(final String projectRoot) async {
  final skillsJsonFile = File(p.join(projectRoot, 'skills.json'));
  if (!skillsJsonFile.existsSync()) {
    return const ValidationReport(
      skills: [],
      ok: false,
      registryWarnings: [
        'Missing required project configuration file: skills.json',
      ],
    );
  }

  // Parse skills.json
  final Set<String> declaredSkills = {};
  try {
    final raw = await skillsJsonFile.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final skillsArray = data['skills'] as List?;
    if (skillsArray != null) {
      for (final item in skillsArray) {
        if (item is Map<String, dynamic>) {
          final skillNames = item['skills'] as List?;
          if (skillNames != null) {
            for (final name in skillNames) {
              if (name is String && name.isNotEmpty) {
                declaredSkills.add(name);
              }
            }
          }
        }
      }
    }
  } on Object catch (e) {
    return ValidationReport(
      skills: const [],
      ok: false,
      registryWarnings: ['Error parsing skills.json: $e'],
    );
  }

  final results = <SkillValidationResult>[];
  final localSkillsDir = Directory(p.join(projectRoot, '.agents', 'skills'));

  // 1. Validate all declared skills
  for (final name in declaredSkills) {
    final skillPath = p.join(localSkillsDir.path, name);
    if (!Directory(skillPath).existsSync()) {
      results.add(
        SkillValidationResult(
          dirName: name,
          errors: ['Declared skill is missing from .agents/skills/$name'],
        ),
      );
    } else {
      final res = await validateSingleSkill(skillPath, name);
      results.add(res);
    }
  }

  // 2. Warn about extra undeclared local directories
  final registryWarnings = <String>[];
  if (localSkillsDir.existsSync()) {
    final entries = await localSkillsDir.list().toList();
    for (final entry in entries) {
      if (entry is Directory) {
        final name = p.basename(entry.path);
        if (!name.startsWith('.') && !declaredSkills.contains(name)) {
          registryWarnings.add(
            'Undeclared skill directory found: .agents/skills/$name (not in skills.json)',
          );
        }
      }
    }
  }

  // 3. Scan for active plan files (ephemeral plans doctrine)
  final activePlans = <String>[];
  final taskFile = File(p.join(projectRoot, 'task.md'));
  if (taskFile.existsSync()) {
    activePlans.add('task.md');
  }
  final planFile = File(p.join(projectRoot, 'implementation_plan.md'));
  if (planFile.existsSync()) {
    activePlans.add('implementation_plan.md');
  }
  final activePlansDir =
      Directory(p.join(projectRoot, 'docs', 'exec-plans', 'active'));
  if (activePlansDir.existsSync()) {
    try {
      final planFiles = activePlansDir.listSync().whereType<File>();
      for (final f in planFiles) {
        final name = p.basename(f.path);
        if (!name.startsWith('.')) {
          activePlans.add('docs/exec-plans/active/$name');
        }
      }
    } catch (_) {}
  }

  for (final plan in activePlans) {
    registryWarnings.add(
      'Stale/active plan file found: $plan. Extract durable findings to ADR/FAQ/Code, then delete the plan file to maintain hygiene.',
    );
  }

  // Run custom validators from steward.json
  try {
    final config = await StewardConfig.load(projectRoot);
    for (final validator in config.validators) {
      final customErrors = await validator.validate(projectRoot);
      registryWarnings.addAll(customErrors);
    }
  } catch (_) {}

  final failedCount = results.where((final r) => !r.isValid).length;
  final ok = failedCount == 0 && registryWarnings.isEmpty;

  return ValidationReport(
    skills: results,
    registryWarnings: registryWarnings,
    ok: ok,
  );
}
