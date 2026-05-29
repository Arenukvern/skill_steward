/// Dart port of eval-skill.mjs — Tier 1 rule-based skill evaluator.
///
/// Mirrors the logic in the original Node script exactly:
///   - Loads YAML eval cases from skills/{name}/evals/cases/*.yaml
///   - Validates case schema
///   - Runs rule checks (file_exists, description_includes_any, etc.)
///   - Weak routing simulation (overlap of input tokens vs description)
///   - Returns [EvalSkillResult] per skill, aggregated in [EvalReport]
///
/// See also:
///   - scripts/eval-tiers.mjs (now: eval_tiers.dart)
///   - skills/skill-eval-improve/references/eval-case-schema.md
///   - docs/decisions/0011-tiered-skill-evals-and-rule-based-ci.md
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../validation/skill_frontmatter.dart';
import 'eval_case.dart';
import 'eval_result.dart';
import 'eval_tiers.dart';

// ─── String helpers (match Node behavior) ────────────────────────────────────

bool _includesAny(final String haystack, final List<String> terms) {
  final h = haystack.toLowerCase();
  return terms.any((final t) => h.contains(t.toLowerCase()));
}

bool _excludesAll(final String haystack, final List<String> terms) {
  final h = haystack.toLowerCase();
  return !terms.any((final t) => h.contains(t.toLowerCase()));
}

// ─── Rule runner ─────────────────────────────────────────────────────────────

/// Runs all [rules] for a single case against [skillPath].
///
/// Reads SKILL.md once (via [parseFrontmatter]) and reads additional
/// files on demand for body_* rules.  Mirrors [runCaseRules] in Node.
Future<List<String>> _runCaseRules(
  final String skillPath,
  final EvalCase evalCase,
) async {
  final errors = <String>[];

  // Read SKILL.md — required for all rule kinds.
  final skillMdFile = File(p.join(skillPath, 'SKILL.md'));
  if (!skillMdFile.existsSync()) {
    return ['SKILL.md not found in $skillPath'];
  }
  final skillMdContent = await skillMdFile.readAsString();
  final parsed = parseFrontmatter(skillMdContent);
  if (parsed.error != null) {
    return [parsed.error!];
  }

  final description = parsed['description'] ?? '';
  final skillMdBody = parsed.body;
  final dirName = p.basename(skillPath);

  // Validate case skill field matches actual directory name.
  if (evalCase.skill != dirName) {
    errors.add(
      'case skill "${evalCase.skill}" != directory "$dirName"',
    );
  }

  for (final rule in evalCase.rules) {
    switch (rule.kind) {
      case 'file_exists':
        final target = File(p.join(skillPath, rule.path ?? ''));
        if (!target.existsSync()) {
          errors.add('file_exists failed: ${rule.path}');
        }

      case 'description_includes_any':
        if (!_includesAny(description, rule.terms)) {
          errors.add(
            'description_includes_any failed: need one of [${rule.terms.join(', ')}]',
          );
        }

      case 'description_excludes_all':
        if (!_excludesAll(description, rule.terms)) {
          errors.add(
            'description_excludes_all failed: must not include [${rule.terms.join(', ')}]',
          );
        }

      case 'body_includes_any':
        final rel = rule.path!;
        String target;
        if (rel == 'SKILL.md') {
          target = skillMdBody;
        } else {
          final f = File(p.join(skillPath, rel));
          if (!f.existsSync()) {
            errors.add('body_includes_any: cannot read $rel');
            break;
          }
          target = await f.readAsString();
        }
        if (!_includesAny(target, rule.terms)) {
          errors.add(
            'body_includes_any failed ($rel): need one of [${rule.terms.join(', ')}]',
          );
        }

      case 'body_excludes_all':
        final rel = rule.path!;
        String target;
        if (rel == 'SKILL.md') {
          target = skillMdBody;
        } else {
          final f = File(p.join(skillPath, rel));
          if (!f.existsSync()) {
            errors.add('body_excludes_all: cannot read $rel');
            break;
          }
          target = await f.readAsString();
        }
        if (!_excludesAll(target, rule.terms)) {
          errors.add(
            'body_excludes_all failed ($rel): must not include [${rule.terms.join(', ')}]',
          );
        }

      default:
        break;
    }
  }

  // ── Weak routing simulation (matches Node exactly) ─────────────────────────
  // Not an agent router — just a coarse sanity check (see ADR 0011).
  final inputLower = evalCase.input.toLowerCase();
  final inputTokens = inputLower
      .split(RegExp(r'\W+'))
      .where((final w) => w.length > 4)
      .take(8)
      .toList();
  final descLower = description.toLowerCase();
  // ignore: unnecessary_lambdas — descLower is a closure capture, tearoff not possible
  final overlap = inputTokens.where((final t) => descLower.contains(t)).length;

  if (evalCase.routing == 'should_trigger' &&
      inputTokens.isNotEmpty &&
      overlap == 0) {
    errors.add(
      'routing hint: should_trigger but no input token (len>4) appears in '
      'description (weak check)',
    );
  }
  if (evalCase.routing == 'should_not_trigger' && overlap >= 3) {
    errors.add(
      'routing hint: should_not_trigger but description overlaps $overlap '
      'input tokens (weak check)',
    );
  }

  return errors;
}

// ─── Per-skill evaluator ──────────────────────────────────────────────────────

/// Evaluates a single skill by name.
///
/// [skillsDir] is the `skills/` directory path.
/// Mirrors the Node [evalSkill] function exactly, including Tier 1 gating.
Future<EvalSkillResult> evalSkill(
  final String skillsDir,
  final String skillName,
) async {
  final skillPath = p.join(skillsDir, skillName);
  final errors = <String>[];
  final warnings = <String>[];

  if (!Directory(skillPath).existsSync()) {
    return EvalSkillResult(
      skillName: skillName,
      errors: ['Unknown skill: $skillName'],
      warnings: const [],
      passed: 0,
      total: 0,
    );
  }

  if (!tier1Skills.contains(skillName)) {
    warnings.add('$skillName is not Tier 1 — skipping case requirements');
    return EvalSkillResult(
      skillName: skillName,
      errors: const [],
      warnings: warnings,
      passed: 0,
      total: 0,
    );
  }

  final casesDir = Directory(p.join(skillPath, 'evals', 'cases'));
  if (!casesDir.existsSync()) {
    errors.add(
      'Tier 1 requires evals/cases/*.yaml (min $tier1MinCases)',
    );
    return EvalSkillResult(
      skillName: skillName,
      errors: errors,
      warnings: warnings,
      passed: 0,
      total: 0,
    );
  }

  final caseFiles = casesDir
      .listSync()
      .whereType<File>()
      .where(
        (final f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'),
      )
      .toList();

  if (caseFiles.length < tier1MinCases) {
    errors.add(
      'Tier 1 requires ≥$tier1MinCases case files; found ${caseFiles.length}',
    );
  }

  var passed = 0;
  var total = 0;

  for (final file in caseFiles) {
    final fileName = p.basename(file.path);
    String raw;
    try {
      raw = await file.readAsString();
    } on Object {
      errors.add('$fileName: unreadable');
      continue;
    }

    dynamic caseObj;
    try {
      caseObj = loadYaml(raw);
    } on Object catch (e) {
      errors.add('$fileName: YAML parse error: $e');
      continue;
    }

    if (caseObj is! Map) {
      errors.add('$fileName: case must be a YAML object');
      continue;
    }

    final evalCase = EvalCase.fromMap(caseObj as Map<Object?, Object?>);
    final schemaErrors = evalCase.validate(fileName);
    if (schemaErrors.isNotEmpty) {
      errors.addAll(schemaErrors);
      continue;
    }

    total++;
    final ruleErrors = await _runCaseRules(skillPath, evalCase);
    if (ruleErrors.isNotEmpty) {
      errors.add('${evalCase.id}: ${ruleErrors.join('; ')}');
    } else {
      passed++;
    }
  }

  return EvalSkillResult(
    skillName: skillName,
    errors: errors,
    warnings: warnings,
    passed: passed,
    total: total,
  );
}

// ─── Aggregate runner ─────────────────────────────────────────────────────────

/// Runs evals for [targets] (defaults to all [tier1Skills]).
///
/// [skillsDir] must be the absolute path to the repo `skills/` directory.
Future<EvalReport> evalAllSkills(
  final String skillsDir, {
  final List<String>? targets,
}) async {
  final names = targets ?? tier1Skills;
  final results = <EvalSkillResult>[];

  for (final name in names) {
    results.add(await evalSkill(skillsDir, name));
  }

  final ok = results.every((final r) => r.isOk);
  return EvalReport(results: results, ok: ok);
}
