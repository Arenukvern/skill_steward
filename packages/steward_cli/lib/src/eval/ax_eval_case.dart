/// Behavioral / routing eval cases under repo-root `evals/cases/*.yaml`.
library;

class AxRepoFileExpect {
  const AxRepoFileExpect({required this.path, required this.terms});

  factory AxRepoFileExpect.fromMap(final Map<Object?, Object?> map) =>
      AxRepoFileExpect(
        path: (map['path'] ?? '') as String,
        terms: AxExpect._stringList(map['terms']),
      );

  final String path;
  final List<String> terms;
}

class AxExpect {
  const AxExpect({
    this.bodyIncludes = const [],
    this.bodyExcludes = const [],
    this.maxSkillKb,
    this.stopLoopEncoded = false,
    this.dispositionTable = false,
    this.blockers = const [],
    this.repoFileIncludes = const [],
  });

  factory AxExpect.fromMap(final Map<Object?, Object?>? map) {
    if (map == null) return const AxExpect();
    final includes = AxExpect._stringList(map['body_includes']);
    final excludes = AxExpect._stringList(map['body_excludes']);
    final blockers = AxExpect._stringList(map['blockers']);
    final maxKb = map['max_skill_kb'];
    final repoRaw = map['repo_file_includes'];
    final repoFiles = repoRaw is List
        ? repoRaw
              .whereType<Map<Object?, Object?>>()
              .map(AxRepoFileExpect.fromMap)
              .toList()
        : const <AxRepoFileExpect>[];
    return AxExpect(
      bodyIncludes: includes,
      bodyExcludes: excludes,
      maxSkillKb: maxKb is int ? maxKb : (maxKb is num ? maxKb.toInt() : null),
      stopLoopEncoded: map['stop_loop_encoded'] == true,
      dispositionTable: map['disposition_table'] == true,
      blockers: blockers,
      repoFileIncludes: repoFiles,
    );
  }

  final List<String> bodyIncludes;
  final List<String> bodyExcludes;
  final int? maxSkillKb;
  final bool stopLoopEncoded;
  final bool dispositionTable;
  final List<String> blockers;
  final List<AxRepoFileExpect> repoFileIncludes;

  static List<String> _stringList(final Object? raw) {
    if (raw is! List) return const [];
    return raw.map((final e) => e.toString()).where((final s) => s.isNotEmpty).toList();
  }

}

class AxEvalCase {
  const AxEvalCase({
    required this.id,
    required this.suite,
    required this.input,
    required this.expectedSkill,
    this.expect = const AxExpect(),
    this.replacesCase,
  });

  factory AxEvalCase.fromMap(final Map<Object?, Object?> map) {
    final expectRaw = map['expect'];
    return AxEvalCase(
      id: (map['id'] ?? '') as String,
      suite: (map['suite'] ?? '') as String,
      input: (map['input'] ?? '') as String,
      expectedSkill: (map['expected_skill'] ?? '') as String,
      expect: expectRaw is Map<Object?, Object?>
          ? AxExpect.fromMap(expectRaw)
          : const AxExpect(),
      replacesCase: map['replaces_case'] as String?,
    );
  }

  static const validSuites = {'routing', 'scenario', 'behavior'};

  final String id;
  final String suite;
  final String input;
  final String expectedSkill;
  final AxExpect expect;
  final String? replacesCase;

  List<String> validate(final String file) {
    final errors = <String>[];
    if (id.isEmpty) errors.add('$file: missing id');
    if (!validSuites.contains(suite)) {
      errors.add('$file: suite must be routing | scenario | behavior');
    }
    if (input.length < 8) {
      errors.add('$file: input must be a realistic prompt (≥8 chars)');
    }
    if (expectedSkill.isEmpty) {
      errors.add('$file: missing expected_skill');
    }
    return errors;
  }
}
