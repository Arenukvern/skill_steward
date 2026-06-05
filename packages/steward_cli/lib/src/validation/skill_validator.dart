import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../repo_root.dart';
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
  final structure = await validateSkillStructure(skillPath, dirName);

  // (Minor duplication of read for name/desc attachment even on error paths.
  //  Acceptable until the full CLI wiring refactor; keeps public surface stable
  //  so existing tests continue to compile without modification.)
  final parsed = await readAndParseSkill(skillPath);

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

/// Validates all skills under the given `skillsDir` (normally the repo `skills/` folder).
///
/// After collecting individual results it also runs the registry cross-checks
/// (skills.sh.json vs on-disk directories) when a root containing skills.sh.json
/// can be located. This fully prepares the Dart port for the registry warnings
/// that the Node validator emits.
///
/// The [ValidationReport] already had the `registryWarnings` field; it is now populated.
///
/// Graceful degradation: if we are not inside a Skill Steward checkout (or the
/// json is absent/broken) we simply omit registry warnings (mirrors Node catch).
///
/// References:
/// - original Node validator main (registry block after per-skill results)
/// - packages/steward_cli/lib/src/repo_root.dart (findRepoRoot)
Future<ValidationReport> validateAllSkills(final String skillsDir) async {
  final dir = Directory(skillsDir);
  if (!dir.existsSync()) {
    return const ValidationReport(skills: [], ok: false);
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

  // --- Registry warnings preparation (the main addition in this iteration) ---
  List<SkillValidationResult> finalSkills = results;
  List<String> registryWarnings = const [];

  try {
    // findRepoRoot walks upward from skillsDir until it sees skills.sh.json.
    // It throws only if we truly cannot find a Skill Steward root at all.
    final root = findRepoRoot(Directory(skillsDir));
    final registryIds = await loadRegistrySkillIds(root);

    final aug = augmentWithRegistryWarnings(results, registryIds);
    finalSkills = aug.augmentedResults;

    final warnings = List<String>.from(aug.registryWarnings);

    // Plan hygiene scan
    final activePlans = <String>[];
    for (final planName in ['task.md', 'implementation_plan.md']) {
      final file = File(p.join(root, planName));
      if (file.existsSync()) {
        activePlans.add(planName);
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
            activePlans.add('docs/exec-plans/active/$name');
          }
        }
      } catch (_) {}
    }

    for (final plan in activePlans) {
      warnings.add(
        'Stale/active plan file found: $plan. Extract durable findings to ADR/FAQ/Code, then delete the plan file to maintain hygiene.',
      );
    }

    // Run Steward contract checks and custom validators from steward.yaml.
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
      final customErrors = await validator.validate(root);
      warnings.addAll(customErrors);
    }

    warnings.addAll(await validatePluginManifests(root));

    registryWarnings = warnings;
  } on Object catch (_) {
    // Not a full checkout or missing/broken skills.sh.json — registry checks skipped.
    // This is the intended graceful behavior (see Node catch in loadSkillsShIds).
  }

  final failed = finalSkills.where((final r) => !r.isValid).length;
  final ok = failed == 0 && registryWarnings.isEmpty;

  return ValidationReport(
    skills: finalSkills,
    registryWarnings: registryWarnings,
    ok: ok,
  );
}

/// Convenience helper that returns the validation result as a JSON string
/// in (approximately) the same shape as the original Node validator --json output.
Future<String> validateAllSkillsToJson(final String skillsDir) async {
  final report = await validateAllSkills(skillsDir);
  final json = const JsonEncoder.withIndent('  ').convert(report.toJson());
  return json;
}
