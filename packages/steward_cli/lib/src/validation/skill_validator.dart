import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../repo_root.dart';
import 'adoption_run_validator.dart';
import 'plugin_manifest_validator.dart';
import 'skill_frontmatter.dart';
import 'skill_rules.dart';
import 'steward_config.dart';
import 'validation_result.dart';

/// Validates a single skill directory against the Agent Skills spec + Skill Steward rules.
///
/// This is the primary entry point for per-skill validation from the Dart side.
/// It is now the canonical implementation used by `steward validate`.
///
/// The heavy lifting is in [validateSkillStructure] + the rules.
Future<SkillValidationResult> validateSingleSkill(
  final String skillPath,
  final String dirName,
) async {
  final parsed = await readAndParseSkill(skillPath);
  final structure = await validateSkillStructure(
    skillPath,
    dirName,
    preParsed: parsed,
  );

  return SkillValidationResult(
    dirName: dirName,
    errors: structure.errors,
    warnings: structure.warnings,
    name: parsed['name'],
    description: parsed['description'],
  );
}

/// Loads the set of skill identifiers declared in the top-level `skills.sh.json`
/// "registry" (the groupings that power skills.sh and docs).
///
/// On any read / parse / schema problem we return the empty set (exactly as
/// `loadSkillsShIds` does in the Node reference). This allows the validator to
/// run gracefully outside a full checkout.
///
/// References:
/// - original Node implementation (validate-skills.mjs): loadRegistry + registry warnings
/// - skills.sh.json (the SSOT for published skill ids)
Future<Set<String>> loadRegistrySkillIds(final String rootDir) async {
  try {
    final file = File(p.join(rootDir, 'skills.sh.json'));
    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final ids = <String>{};

    // Support flat skills list
    final flatSkills = data['skills'];
    if (flatSkills is List) {
      for (final id in flatSkills) {
        if (id is String && id.isNotEmpty) {
          ids.add(id);
        }
      }
    }

    // Support grouped skills list
    final groupings = (data['groupings'] as List?) ?? const [];
    for (final g in groupings) {
      if (g is Map<String, dynamic>) {
        final skills = (g['skills'] as List?) ?? const [];
        for (final id in skills) {
          if (id is String && id.isNotEmpty) {
            ids.add(id);
          }
        }
      }
    }
    return ids;
  } on Object catch (_) {
    return <String>{};
  }
}

/// Given already-computed per-skill results + the registry id set, produces:
/// - per-skill "not listed in skills.sh.json" warnings (attached only when registry non-empty)
/// - top-level registryWarnings for ids in the json that have no matching skill dir
///
/// The logic and exact warning strings are copied from the post-processing section
/// of the original Node validator (after the per-skill loop).
///
/// We return a fresh list of [SkillValidationResult] because the class is immutable.
({List<SkillValidationResult> augmentedResults, List<String> registryWarnings})
augmentWithRegistryWarnings(
  final List<SkillValidationResult> results,
  final Set<String> registryIds,
) {
  final registryWarnings = <String>[];

  final skillNames = results
      .map((final r) => r.name)
      .whereType<String>()
      .toSet();

  for (final id in registryIds) {
    if (!skillNames.contains(id)) {
      registryWarnings.add(
        'skills.sh.json references "$id" but no matching skill directory found',
      );
    }
  }

  final augmented = <SkillValidationResult>[];
  for (final r in results) {
    List<String> newWarnings = r.warnings;
    if (r.name != null &&
        registryIds.isNotEmpty &&
        !registryIds.contains(r.name)) {
      newWarnings = [
        ...r.warnings,
        'Skill "${r.name}" not listed in skills.sh.json groupings',
      ];
    }
    augmented.add(
      SkillValidationResult(
        dirName: r.dirName,
        errors: r.errors,
        warnings: newWarnings,
        name: r.name,
        description: r.description,
      ),
    );
  }

  return (augmentedResults: augmented, registryWarnings: registryWarnings);
}

const skillsValidationGroup = 'skills';
const registryValidationGroup = 'registry';
const repoContractValidationGroup = 'repoContract';
const evidenceValidationGroup = 'evidence';

Future<List<SkillValidationResult>> _collectSkillResults(
  final String skillsDir,
) async {
  final dir = Directory(skillsDir);
  if (!dir.existsSync()) {
    return const [];
  }

  final entries = await dir.list().toList();
  final skillDirs =
      entries
          .whereType<Directory>()
          .map((final d) => d.path)
          .where((final path) => !p.basename(path).startsWith('.'))
          .toList()
        ..sort();

  final results = <SkillValidationResult>[];
  for (final path in skillDirs) {
    final dirName = p.basename(path);
    final result = await validateSingleSkill(path, dirName);
    results.add(result);
  }
  return results;
}

ValidationGroupResult _skillsGroup(final List<SkillValidationResult> skills) {
  final failed = skills.where((final r) => !r.isValid).length;
  return ValidationGroupResult(
    ok: failed == 0,
    checked: skills.length,
    failed: failed,
  );
}

/// Validates only the installable skill directories.
Future<ValidationReport> validateSkillsDirectory(final String skillsDir) async {
  final dir = Directory(skillsDir);
  if (!dir.existsSync()) {
    return const ValidationReport(
      skills: [],
      ok: false,
      groups: {
        skillsValidationGroup: ValidationGroupResult(
          ok: false,
          errors: ['skills directory not found'],
        ),
      },
    );
  }

  final skills = await _collectSkillResults(skillsDir);
  final group = _skillsGroup(skills);
  return ValidationReport(
    skills: skills,
    ok: group.ok,
    groups: {skillsValidationGroup: group},
  );
}

/// Validates the central skills.sh.json registry against skill directories.
Future<ValidationReport> validateSkillRegistry(final String skillsDir) async {
  final skills = await _collectSkillResults(skillsDir);
  final skillsGroup = _skillsGroup(skills);

  try {
    final root = findRepoRoot(Directory(skillsDir));
    final registryIds = await loadRegistrySkillIds(root);
    final aug = augmentWithRegistryWarnings(skills, registryIds);
    final registryWarnings = aug.registryWarnings;
    final registryGroup = ValidationGroupResult(
      ok: registryWarnings.isEmpty,
      checked: registryIds.length,
      failed: registryWarnings.length,
      warnings: registryWarnings,
    );
    return ValidationReport(
      skills: aug.augmentedResults,
      registryWarnings: registryWarnings,
      ok: skillsGroup.ok && registryGroup.ok,
      groups: {
        skillsValidationGroup: _skillsGroup(aug.augmentedResults),
        registryValidationGroup: registryGroup,
      },
    );
  } on Object catch (error) {
    final registryGroup = ValidationGroupResult(
      ok: false,
      failed: 1,
      errors: ['Registry validation failed: $error'],
    );
    return ValidationReport(
      skills: skills,
      registryWarnings: registryGroup.errors,
      ok: false,
      groups: {
        skillsValidationGroup: skillsGroup,
        registryValidationGroup: registryGroup,
      },
    );
  }
}

/// Validates repo-level Steward contract surfaces.
Future<ValidationReport> validateRepoContract(final String root) async {
  final warnings = <String>[];

  for (final planName in ['task.md', 'implementation_plan.md']) {
    final file = File(p.join(root, planName));
    if (file.existsSync()) {
      warnings.add(
        'Stale/active plan file found: $planName. Extract durable findings to ADR/FAQ/Code, then delete the plan file to maintain hygiene.',
      );
    }
  }
  final activePlansDir = Directory(
    p.join(root, 'docs', 'exec-plans', 'active'),
  );
  if (activePlansDir.existsSync()) {
    try {
      final files = activePlansDir.listSync().whereType<File>();
      for (final f in files) {
        final name = p.basename(f.path);
        if (!name.startsWith('.')) {
          warnings.add(
            'Stale/active plan file found: docs/exec-plans/active/$name. Extract durable findings to ADR/FAQ/Code, then delete the plan file to maintain hygiene.',
          );
        }
      }
    } on Object catch (error) {
      warnings.add('Plan hygiene scan failed: $error');
    }
  }

  try {
    final configResult = await StewardConfig.loadChecked(root);
    final config = configResult.config;
    if (config.configPath != null) {
      warnings.addAll(
        configResult.diagnostics
            .where((final diagnostic) => diagnostic.isError)
            .map(
              (final diagnostic) => '${diagnostic.path}: ${diagnostic.message}',
            ),
      );
    }
    for (final validator in config.validators) {
      try {
        warnings.addAll(await validator.validate(root));
      } on Object catch (error) {
        warnings.add('Custom validator ${validator.type} failed: $error');
      }
    }
  } on Object catch (error) {
    warnings.add('Steward contract validation failed: $error');
  }

  try {
    warnings.addAll(await validatePluginManifests(root));
  } on Object catch (error) {
    warnings.add('Plugin manifest validation failed: $error');
  }

  final group = ValidationGroupResult(
    ok: warnings.isEmpty,
    failed: warnings.length,
    warnings: warnings,
  );
  return ValidationReport(
    skills: const [],
    registryWarnings: warnings,
    ok: group.ok,
    groups: {repoContractValidationGroup: group},
  );
}

/// Validates committed adoption-run evidence records.
Future<ValidationReport> validateEvidence(final String root) async {
  final warnings = <String>[];
  try {
    warnings.addAll(await validateAdoptionRunEvidence(root));
  } on Object catch (error) {
    warnings.add('Evidence validation failed: $error');
  }

  final group = ValidationGroupResult(
    ok: warnings.isEmpty,
    failed: warnings.length,
    warnings: warnings,
  );
  return ValidationReport(
    skills: const [],
    registryWarnings: warnings,
    ok: group.ok,
    groups: {evidenceValidationGroup: group},
  );
}

/// Validates all skills under the given `skillsDir` (normally the repo `skills/` folder).
///
/// This is the CI-friendly umbrella over the split ownership lanes:
/// skill structure, registry, repo contract, and evidence.
///
/// References:
/// - original Node validator main (registry block after per-skill results)
/// - packages/steward_cli/lib/src/repo_root.dart (findRepoRoot)
Future<ValidationReport> validateAllSkills(final String skillsDir) async {
  final registry = await validateSkillRegistry(skillsDir);
  final groups = Map<String, ValidationGroupResult>.from(registry.groups);
  final warnings = <String>[...registry.registryWarnings];

  try {
    final root = findRepoRoot(Directory(skillsDir));
    final repoContract = await validateRepoContract(root);
    final evidence = await validateEvidence(root);
    groups
      ..addAll(repoContract.groups)
      ..addAll(evidence.groups);
    warnings
      ..addAll(repoContract.registryWarnings)
      ..addAll(evidence.registryWarnings);
  } on Object catch (error) {
    final group = ValidationGroupResult(
      ok: false,
      failed: 1,
      errors: ['Repo validation root lookup failed: $error'],
    );
    groups[repoContractValidationGroup] = group;
    warnings.addAll(group.errors);
  }

  final ok = groups.values.every((final group) => group.ok);

  return ValidationReport(
    skills: registry.skills,
    registryWarnings: warnings,
    ok: ok,
    groups: groups,
  );
}

/// Convenience helper that returns the validation result as a JSON string
/// in (approximately) the same shape as the original Node validator --json output.
Future<String> validateAllSkillsToJson(final String skillsDir) async {
  final report = await validateAllSkills(skillsDir);
  final json = const JsonEncoder.withIndent('  ').convert(report.toJson());
  return json;
}
