/// Result types for the Dart eval runner.
library;

/// Result for a single Tier 1 skill evaluation.
class EvalSkillResult {
  final String skillName;
  final List<String> errors;
  final List<String> warnings;
  final int passed;
  final int total;

  // ignore: sort_constructors_first
  const EvalSkillResult({
    required this.skillName,
    required this.errors,
    required this.warnings,
    required this.passed,
    required this.total,
  });

  bool get isOk => errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'skillName': skillName,
        'errors': errors,
        'warnings': warnings,
        'passed': passed,
        'total': total,
      };
}

/// Overall eval report across all skills.
class EvalReport {
  final List<EvalSkillResult> results;
  final bool ok;

  // ignore: sort_constructors_first
  const EvalReport({required this.results, required this.ok});

  Map<String, dynamic> toJson() => {
        'results': results.map((final r) => r.toJson()).toList(),
        'exitCode': ok ? 0 : 1,
      };
}
