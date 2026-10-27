/// Runs repo-root AX behavioral eval cases (`evals/cases/*.yaml`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'ax_eval_case.dart';
import 'ax_skill_router.dart';

class AxCaseResult {
  const AxCaseResult({
    required this.id,
    required this.suite,
    required this.expectedSkill,
    required this.predictedSkill,
    required this.routingOk,
    required this.missedBlockers,
    required this.kbLoaded,
    required this.loopsPastTwoRisk,
    this.errors = const [],
  });

  final String id;
  final String suite;
  final String expectedSkill;
  final String predictedSkill;
  final bool routingOk;
  final bool missedBlockers;
  final int kbLoaded;
  final bool loopsPastTwoRisk;
  final List<String> errors;

  Map<String, dynamic> toJson() => {
    'id': id,
    'suite': suite,
    'expected_skill': expectedSkill,
    'predicted_skill': predictedSkill,
    'routing_ok': routingOk,
    'missed_blockers': missedBlockers,
    'kb_loaded': kbLoaded,
    'loops_past_two_risk': loopsPastTwoRisk,
    if (errors.isNotEmpty) 'errors': errors,
  };
}

class AxSignalRates {
  const AxSignalRates({
    required this.routingAccuracy,
    required this.missedBlockersRate,
    required this.meanKbLoaded,
    required this.loopsPastTwoRate,
  });

  final double routingAccuracy;
  final double missedBlockersRate;
  final double meanKbLoaded;
  final double loopsPastTwoRate;

  Map<String, dynamic> toJson() => {
    'routing_accuracy': routingAccuracy,
    'missed_blockers_rate': missedBlockersRate,
    'mean_kb_skill_loaded': meanKbLoaded,
    'loops_past_two_rate': loopsPastTwoRate,
  };
}

class AxEvalReport {
  const AxEvalReport({
    required this.ok,
    required this.cases,
    required this.signals,
    required this.measurement,
    required this.runIndex,
  });

  final bool ok;
  final List<AxCaseResult> cases;
  final AxSignalRates signals;
  final String measurement;
  final int runIndex;

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'measurement': measurement,
    'run_index': runIndex,
    'signals': signals.toJson(),
    'cases': cases.map((final c) => c.toJson()).toList(),
  };
}

bool _includesAny(final String haystack, final List<String> terms) {
  final h = haystack.toLowerCase();
  return terms.any((final t) => h.contains(t.toLowerCase()));
}

bool _stopLoopEncoded(final String body) {
  final lower = body.toLowerCase();
  final hasTwo =
      lower.contains('two attempt') ||
      lower.contains('two learning loop') ||
      lower.contains('two failed') ||
      lower.contains('after two');
  final hasStop =
      lower.contains('stop') ||
      lower.contains('hand off') ||
      lower.contains('rewrite') ||
      lower.contains('disposition');
  return hasTwo && hasStop;
}

bool _dispositionTableEncoded(final String body) {
  final lower = body.toLowerCase();
  return lower.contains('disposition') &&
      (lower.contains('table') || lower.contains('orient'));
}

Future<String> _skillBody(
  final String skillsDir,
  final String skillName,
) async {
  if (skillName == 'none') return '';
  final file = File(p.join(skillsDir, skillName, 'SKILL.md'));
  if (!file.existsSync()) return '';
  final content = await file.readAsString();
  final idx = content.indexOf('\n---\n');
  if (idx >= 0 && content.startsWith('---')) {
    final end = content.indexOf('\n---\n', 4);
    if (end >= 0) return content.substring(end + 5);
  }
  return content;
}

Future<List<AxEvalCase>> loadAxCases(final String casesDir) async {
  final dir = Directory(casesDir);
  if (!dir.existsSync()) return [];
  final cases = <AxEvalCase>[];
  for (final file in dir
      .listSync()
      .whereType<File>()
      .where((final f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))) {
    final raw = await file.readAsString();
    final obj = loadYaml(raw);
    if (obj is! Map) continue;
    final case_ = AxEvalCase.fromMap(obj as Map<Object?, Object?>);
    final errors = case_.validate(p.basename(file.path));
    if (errors.isNotEmpty) {
      throw FormatException(errors.join('; '));
    }
    cases.add(case_);
  }
  cases.sort((final a, final b) => a.id.compareTo(b.id));
  return cases;
}

AxSignalRates _aggregateSignals(final List<AxCaseResult> results) {
  if (results.isEmpty) {
    return const AxSignalRates(
      routingAccuracy: 0,
      missedBlockersRate: 0,
      meanKbLoaded: 0,
      loopsPastTwoRate: 0,
    );
  }
  var routingHits = 0;
  var blockerMisses = 0;
  var kbSum = 0;
  var loopRisks = 0;
  for (final r in results) {
    if (r.routingOk) routingHits++;
    if (r.missedBlockers) blockerMisses++;
    kbSum += r.kbLoaded;
    if (r.loopsPastTwoRisk) loopRisks++;
  }
  final n = results.length;
  return AxSignalRates(
    routingAccuracy: routingHits / n,
    missedBlockersRate: blockerMisses / n,
    meanKbLoaded: kbSum / n,
    loopsPastTwoRate: loopRisks / n,
  );
}

Future<AxEvalReport> runAxEvalSuite(
  final String repoRoot, {
  final int runIndex = 1,
}) async {
  const measurement =
      'deterministic_description_router_v1 (not live agent sessions)';
  final skillsDir = p.join(repoRoot, 'skills');
  final casesDir = p.join(repoRoot, 'evals', 'cases');
  final cases = await loadAxCases(casesDir);
  final profiles = await loadSkillRoutingProfiles(skillsDir);

  final results = <AxCaseResult>[];
  for (final case_ in cases) {
    final decision = routePrompt(case_.input, profiles);
    final predicted = decision.skill;
    final routingOk = predicted == case_.expectedSkill;

    final bodyForOracle = routingOk
        ? await _skillBody(skillsDir, case_.expectedSkill)
        : await _skillBody(skillsDir, predicted);

    final errors = <String>[];
    var missedBlockers = false;

    if (case_.expect.blockers.isNotEmpty) {
      if (!_includesAny(bodyForOracle, case_.expect.blockers)) {
        missedBlockers = true;
        errors.add('missing blockers in skill text');
      }
    }
    for (final term in case_.expect.bodyIncludes) {
      if (!_includesAny(bodyForOracle, [term])) {
        missedBlockers = true;
        errors.add('body missing: $term');
      }
    }
    for (final term in case_.expect.bodyExcludes) {
      if (_includesAny(bodyForOracle, [term])) {
        missedBlockers = true;
        errors.add('body must not include: $term');
      }
    }
    for (final fileExpect in case_.expect.repoFileIncludes) {
      final file = File(p.join(repoRoot, fileExpect.path));
      if (!file.existsSync()) {
        missedBlockers = true;
        errors.add('repo file missing: ${fileExpect.path}');
      } else {
        final text = await file.readAsString();
        for (final term in fileExpect.terms) {
          if (!_includesAny(text, [term])) {
            missedBlockers = true;
            errors.add('${fileExpect.path} missing: $term');
          }
        }
      }
    }

    final kb = routingOk
        ? skillKbForProfile(profiles, case_.expectedSkill)
        : skillKbForProfile(profiles, predicted);

    if (case_.expect.maxSkillKb != null && kb > case_.expect.maxSkillKb!) {
      missedBlockers = true;
      errors.add('kb $kb > max ${case_.expect.maxSkillKb}');
    }

    var loopsPastTwoRisk = false;
    if (case_.expect.stopLoopEncoded && !_stopLoopEncoded(bodyForOracle)) {
      loopsPastTwoRisk = true;
      errors.add('stop-after-two not encoded');
    }
    if (case_.expect.dispositionTable &&
        !_dispositionTableEncoded(bodyForOracle)) {
      loopsPastTwoRisk = true;
      errors.add('disposition path not encoded');
    }

    if (!routingOk) {
      missedBlockers = true;
      errors.add('routing: expected ${case_.expectedSkill}, got $predicted');
    }

    results.add(
      AxCaseResult(
        id: case_.id,
        suite: case_.suite,
        expectedSkill: case_.expectedSkill,
        predictedSkill: predicted,
        routingOk: routingOk,
        missedBlockers: missedBlockers,
        kbLoaded: kb,
        loopsPastTwoRisk: loopsPastTwoRisk,
        errors: errors,
      ),
    );
  }

  final signals = _aggregateSignals(results);
  final ok = results.every(
    (final r) => r.routingOk && !r.missedBlockers && !r.loopsPastTwoRisk,
  );

  return AxEvalReport(
    ok: ok,
    cases: results,
    signals: signals,
    measurement: measurement,
    runIndex: runIndex,
  );
}

Future<Map<String, dynamic>> runAxBaseline(
  final String repoRoot, {
  final int runs = 3,
}) async {
  final runReports = <Map<String, dynamic>>[];
  for (var i = 1; i <= runs; i++) {
    final report = await runAxEvalSuite(repoRoot, runIndex: i);
    runReports.add(report.toJson());
  }

  final first = runReports.first['signals'] as Map<String, dynamic>;
  final stable = runReports.every((final r) {
    final s = r['signals'] as Map<String, dynamic>;
    return s['routing_accuracy'] == first['routing_accuracy'] &&
        s['missed_blockers_rate'] == first['missed_blockers_rate'] &&
        s['mean_kb_skill_loaded'] == first['mean_kb_skill_loaded'] &&
        s['loops_past_two_rate'] == first['loops_past_two_rate'];
  });

  final profiles = await loadSkillRoutingProfiles(p.join(repoRoot, 'skills'));
  final skillMdKb = <String, int>{
    for (final p in profiles) p.name: (p.skillBodyBytes / 1024).ceil(),
  };

  return {
    'baseline_id': 'ax-guild-skills-${DateTime.now().toUtc().toIso8601String().substring(0, 10)}',
    'git_revision': await _gitHead(repoRoot),
    'measurement': runReports.first['measurement'],
    'skill_md_kb': skillMdKb,
    'runs': runs,
    'deterministic': stable,
    'non_claims': [
      'Not live agent sessions or skillgrade pairs.',
      'Router scores description + When to/not sections only.',
      'KB loaded is SKILL.md body size for the routed skill, not references.',
    ],
    'signals_per_run': runReports.map((final r) => r['signals']).toList(),
    'signal_means': first,
    'failed_cases': _failedCaseIds(runReports.last),
  };
}

List<String> _failedCaseIds(final Map<String, dynamic> lastRun) {
  final cases = lastRun['cases'] as List<dynamic>;
  return cases
      .whereType<Map<String, dynamic>>()
      .where(
        (final c) =>
            c['routing_ok'] != true ||
            c['missed_blockers'] == true ||
            c['loops_past_two_risk'] == true,
      )
      .map((final c) => c['id'] as String)
      .toList();
}

Future<String?> _gitHead(final String repoRoot) async {
  final result = await Process.run('git', [
    '-C',
    repoRoot,
    'rev-parse',
    'HEAD',
  ]);
  if (result.exitCode != 0) return null;
  return (result.stdout as String).trim();
}

String encodeAxBaselineJson(final Map<String, dynamic> baseline) =>
    const JsonEncoder.withIndent('  ').convert(baseline);
