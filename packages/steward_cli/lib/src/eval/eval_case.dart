/// Dart representation of a single eval case loaded from a YAML file.
///
/// Mirrors the schema documented in:
///   skills/skill-eval-improve/references/eval-case-schema.md
///
/// Supported rule kinds (matching eval-skill.mjs):
///   file_exists, description_includes_any, description_excludes_all,
///   body_includes_any, body_excludes_all
library;

/// A single rule inside an eval case.
class EvalRule {
  // ignore: sort_constructors_first
  const EvalRule({required this.kind, this.path, this.terms = const []});

  /// Parses a single rule map from YAML (already decoded).
  factory EvalRule.fromMap(final Map<Object?, Object?> map) {
    final kind = (map['kind'] ?? '') as String;
    final path = map['path'] as String?;
    final rawTerms = map['terms'];
    final terms = rawTerms is List
        ? rawTerms.map((final t) => t.toString()).toList()
        : const <String>[];
    return EvalRule(kind: kind, path: path, terms: terms);
  }

  static const _bodyKinds = {
    'body_includes_any',
    'body_excludes_all',
  };
  static const _termKinds = {
    'description_includes_any',
    'description_excludes_all',
    'body_includes_any',
    'body_excludes_all',
  };

  static const validKinds = {
    'file_exists',
    'description_includes_any',
    'description_excludes_all',
    'body_includes_any',
    'body_excludes_all',
  };

  final String kind;

  /// Required for [file_exists], [body_includes_any], [body_excludes_all].
  final String? path;

  /// Required for [description_includes_any], [description_excludes_all],
  /// [body_includes_any], [body_excludes_all].
  final List<String> terms;

  /// Validates this rule and returns error strings (empty == valid).
  List<String> validate(final String file, final int index) {
    final errors = <String>[];
    if (!validKinds.contains(kind)) {
      errors.add('$file: rules[$index].kind unknown: $kind');
    }
    if (kind == 'file_exists' && (path == null || path!.isEmpty)) {
      errors.add('$file: rules[$index].path required for file_exists');
    }
    if (_termKinds.contains(kind) && terms.isEmpty) {
      errors.add('$file: rules[$index].terms must be non-empty array');
    }
    if (_bodyKinds.contains(kind) && (path == null || path!.isEmpty)) {
      errors.add('$file: rules[$index].path required for body_* rules');
    }
    return errors;
  }
}

/// A parsed eval case from a YAML file.
class EvalCase {
  const EvalCase({
    required this.id,
    required this.skill,
    required this.routing,
    required this.input,
    required this.rules,
  });

  /// Parses a case from an already-decoded YAML map.
  factory EvalCase.fromMap(final Map<Object?, Object?> map) {
    final id = (map['id'] ?? '') as String;
    final skill = (map['skill'] ?? '') as String;
    final routing = (map['routing'] ?? '') as String;
    final input = (map['input'] ?? '') as String;

    final rawRules = map['rules'];
    final rules = rawRules is List
        ? rawRules
            .whereType<Map<Object?, Object?>>()
            .map(EvalRule.fromMap)
            .toList()
        : const <EvalRule>[];

    return EvalCase(
      id: id,
      skill: skill,
      routing: routing,
      input: input,
      rules: rules,
    );
  }

  static const _validRoutings = {'should_trigger', 'should_not_trigger'};

  final String id;
  final String skill;
  final String routing;
  final String input;
  final List<EvalRule> rules;

  /// Validates schema; returns error strings (empty == valid).
  List<String> validate(final String file) {
    final errors = <String>[];
    if (id.isEmpty) errors.add('$file: missing id');
    if (skill.isEmpty) errors.add('$file: missing skill');
    if (!_validRoutings.contains(routing)) {
      errors.add(
        '$file: routing must be should_trigger | should_not_trigger',
      );
    }
    if (input.length < 8) {
      errors.add(
        '$file: input must be a realistic user prompt (≥8 chars)',
      );
    }
    if (rules.isEmpty) {
      errors.add('$file: rules must be a non-empty array');
    } else {
      for (var i = 0; i < rules.length; i++) {
        errors.addAll(rules[i].validate(file, i));
      }
    }
    return errors;
  }
}
