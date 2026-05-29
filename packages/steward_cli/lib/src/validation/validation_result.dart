/// Result of validating a single skill directory.
///
/// Mirrors the per-skill object returned by the Node implementation in
/// original Node validateSkill (plus the registry augmentation
/// performed later in main()).
///
/// Populated by [validateSingleSkill] / [validateAllSkills].
class SkillValidationResult {
  const SkillValidationResult({
    required this.dirName,
    this.errors = const [],
    this.warnings = const [],
    this.name,
    this.description,
  });
  final String dirName;
  final List<String> errors;
  final List<String> warnings;
  final String? name;

  final String? description;

  bool get isValid => errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'dirName': dirName,
        'errors': errors,
        'warnings': warnings,
        'name': name,
        'description': description,
      };

  @override
  String toString() {
    final icon = isValid ? '✓' : '✗';
    return '$icon $dirName';
  }
}

/// Overall validation report for the entire skills/ directory.
///
/// The [registryWarnings] list (and the per-skill "not listed..." warnings)
/// are now produced by the Dart port (see skill_validator.dart).
///
/// Matches the shape of the JSON emitted by the original Node validator --json output
/// (when registry processing has run).
class ValidationReport {
  const ValidationReport({
    required this.skills,
    required this.ok,
    this.registryWarnings = const [],
  });
  final List<SkillValidationResult> skills;
  final List<String> registryWarnings;

  final bool ok;

  List<SkillValidationResult> get failed =>
      skills.where((final s) => !s.isValid).toList();

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'skills': skills.map((final s) => s.toJson()).toList(),
        if (registryWarnings.isNotEmpty) 'registryWarnings': registryWarnings,
      };
}
