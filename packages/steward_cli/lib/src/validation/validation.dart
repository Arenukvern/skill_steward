/// Barrel export for the Dart port of the skill validation logic.
///
/// The implementation aims for high fidelity with the reference:
///   (originally scripts/validate-skills.mjs, removed after hardcut)
///
/// All rule logic lives under this package. The public surface
/// (validateSingleSkill, validateAllSkills, the result classes, etc.)
/// is re-exported here.
///
/// See the individual files for detailed cross-references to the
/// Node original and to evals/fixtures/validate/ cases.
library;

export 'local_validator.dart' show validateLocalSkills;
export 'plugin_manifest_validator.dart' show validatePluginManifests;
export 'skill_frontmatter.dart';
export 'skill_rules.dart';
export 'skill_validator.dart'
    show validateAllSkills, validateAllSkillsToJson, validateSingleSkill;
export 'steward_config.dart';
export 'validation_result.dart';
