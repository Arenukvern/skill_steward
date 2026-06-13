/// Result types for the Dart eval runner.
library;

/// Overall eval report across all skills.
class EvalReport {
  const EvalReport({required this.results, required this.ok});
  final List<EvalSkillResult> results;

  final bool ok;

  Map<String, dynamic> toJson() => {
    'results': results.map((final r) => r.toJson()).toList(),
    'exitCode': ok ? 0 : 1,
  };
}

/// Result for a single T1 behavior-critical skill evaluation.
class EvalSkillResult {
  const EvalSkillResult({
    required this.skillName,
    required this.errors,
    required this.warnings,
    required this.passed,
    required this.total,
  });
  final String skillName;
  final List<String> errors;
  final List<String> warnings;
  final int passed;

  final int total;

  bool get isOk => errors.isEmpty;

  Map<String, dynamic> toJson() => {
    'skillName': skillName,
    'errors': errors,
    'warnings': warnings,
    'passed': passed,
    'total': total,
  };
}
