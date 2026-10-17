#!/usr/bin/env dart

// Offline observations only. Does not run agents, grade artifacts, or promote.
import 'dart:convert';
import 'dart:io';

const metrics = <String>[
  'duration_ms',
  'time_to_first_useful_action_ms',
  'tool_calls',
  'repair_attempts',
  'human_interventions',
  'tokens',
  'cost_usd',
];

void main(List<String> args) {
  if (args.length != 1 || args.single == '--help') {
    stdout.writeln('Usage: dart compare_dogfood.dart <paired-runs.json>');
    if (args.length != 1) exitCode = 2;
    return;
  }
  try {
    final input = jsonDecode(File(args.single).readAsStringSync());
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(compareDogfood(input)),
    );
  } on FormatException catch (error) {
    stderr.writeln('Invalid comparison: ${error.message}');
    exitCode = 2;
  } on FileSystemException catch (error) {
    stderr.writeln('Cannot read comparison: ${error.message}');
    exitCode = 2;
  }
}

Map<String, Object?> compareDogfood(Object? input) {
  final document = object(input, 'document');
  if (document['format'] != 'steward-paired-dogfood/v1') {
    throw const FormatException('Expected steward-paired-dogfood/v1');
  }
  final experiment = requiredText(document, 'experiment');
  final kind = requiredText(document, 'kind');
  if (!{'agent', 'native_control', 'synthetic'}.contains(kind)) {
    throw const FormatException(
      'kind must be agent, native_control, or synthetic',
    );
  }
  final configuration = requiredText(document, 'configuration_ref');
  final baselineRef = requiredText(document, 'baseline_ref');
  final candidateRef = requiredText(document, 'candidate_ref');
  final rawPairs = document['pairs'];
  if (rawPairs is! List || rawPairs.isEmpty) {
    throw const FormatException('pairs must be a nonempty list');
  }
  final ids = <String>{};
  final tasks = <String, List<(Map<String, dynamic>, Map<String, dynamic>)>>{};
  final all = <(Map<String, dynamic>, Map<String, dynamic>)>[];
  var wins = 0;
  var regressions = 0;
  var incomplete = 0;
  var unsafe = 0;
  for (final value in rawPairs) {
    final pair = object(value, 'pair');
    final id = requiredText(pair, 'id');
    if (!ids.add(id)) throw FormatException('Duplicate pair id: $id');
    final task = requiredText(pair, 'task_id');
    final baseline = checkedRun(pair['baseline'], '$id baseline');
    final candidate = checkedRun(pair['candidate'], '$id candidate');
    if (baseline['context_ref'] != candidate['context_ref']) {
      throw FormatException(
        '$id has unmatched context_ref (task/environment/grader/budget)',
      );
    }
    final blocked = [baseline, candidate].any(
      (run) =>
          {'blocked', 'error'}.contains(run['outcome']) ||
          run['safety_violations'] == null,
    );
    if (blocked) {
      incomplete++;
    } else {
      if (!passed(baseline) && passed(candidate)) wins++;
      if (passed(baseline) && !passed(candidate)) regressions++;
    }
    if (candidate['safety_violations'] case final int count when count > 0)
      unsafe++;
    final entry = (baseline, candidate);
    all.add(entry);
    tasks.putIfAbsent(task, () => []).add(entry);
  }
  final bothPassed = all.where((p) => passed(p.$1) && passed(p.$2)).toList();
  return <String, Object?>{
    'format': 'steward-paired-dogfood-summary/v1',
    'experiment': experiment,
    'kind': kind,
    'configuration_ref': configuration,
    'baseline_ref': baselineRef,
    'candidate_ref': candidateRef,
    'status': unsafe > 0
        ? 'unsafe_candidate'
        : regressions > 0
        ? 'quality_regression'
        : incomplete > 0
        ? 'inconclusive'
        : 'descriptive_only',
    'pair_count': all.length,
    'task_count': tasks.length,
    'baseline_passes': all.where((p) => passed(p.$1)).length,
    'candidate_passes': all.where((p) => passed(p.$2)).length,
    'quality_wins': wins,
    'quality_regressions': regressions,
    'incomplete_pairs': incomplete,
    'unsafe_candidate_runs': unsafe,
    'candidate_invocation': {
      'known': all.where((p) => p.$2['skill_invoked'] is bool).length,
      'invoked': all.where((p) => p.$2['skill_invoked'] == true).length,
    },
    'both_passed_pairs': bothPassed.length,
    'metrics_both_passed': metricSummary(bothPassed),
    'metrics_all_attempts': metricSummary(all),
    'tasks': {
      for (final task in tasks.entries)
        task.key: {
          'trials': task.value.length,
          'baseline_all_passed': task.value.every((p) => passed(p.$1)),
          'candidate_all_passed': task.value.every((p) => passed(p.$2)),
        },
    },
    'promotion': 'not_assessed',
    'limitations': [
      'Caller-supplied observations; evidence and isolation are not authenticated.',
      'Descriptive paired deltas only; no confidence interval or causal claim.',
      'All-attempt costs include failures; use both-passed metrics for efficiency.',
      if (kind != 'agent')
        'This is not evidence of agent or skill effectiveness.',
    ],
  };
}

Map<String, dynamic> object(Object? value, String label) {
  if (value is! Map<String, dynamic>)
    throw FormatException('$label must be an object');
  return value;
}

String requiredText(Map<String, dynamic> value, String key) {
  final text = value[key];
  if (text is! String || text.trim().isEmpty)
    throw FormatException('$key must be nonempty text');
  return text;
}

Map<String, dynamic> checkedRun(Object? value, String label) {
  final run = object(value, label);
  requiredText(run, 'context_ref');
  requiredText(run, 'evidence_ref');
  if (!{'pass', 'fail', 'blocked', 'error'}.contains(run['outcome'])) {
    throw FormatException(
      '$label outcome must be pass, fail, blocked, or error',
    );
  }
  final safety = run['safety_violations'];
  if (!run.containsKey('safety_violations') ||
      (safety != null && (safety is! int || safety < 0))) {
    throw FormatException(
      '$label needs a nonnegative safety_violations count or explicit null',
    );
  }
  if (run['skill_invoked'] != null && run['skill_invoked'] is! bool) {
    throw FormatException('$label skill_invoked must be boolean or null');
  }
  for (final metric in metrics) {
    final number = run[metric];
    if (number == null) continue;
    if (number is! num || !number.isFinite || number < 0) {
      throw FormatException(
        '$label $metric must be nonnegative, finite, or null',
      );
    }
  }
  return run;
}

bool passed(Map<String, dynamic> run) =>
    run['outcome'] == 'pass' && run['safety_violations'] == 0;

Map<String, Object?> metricSummary(
  List<(Map<String, dynamic>, Map<String, dynamic>)> pairs,
) {
  return {
    for (final metric in metrics)
      metric: deltaSummary([
        for (final pair in pairs)
          if (pair.$1[metric] is num && pair.$2[metric] is num)
            (pair.$2[metric] as num) - (pair.$1[metric] as num),
      ], pairs.length),
  };
}

Map<String, Object?> deltaSummary(List<num> deltas, int eligible) {
  deltas.sort();
  final middle = deltas.length ~/ 2;
  return {
    'observed_pairs': deltas.length,
    'missing_pairs': eligible - deltas.length,
    'median_candidate_minus_baseline': deltas.isEmpty
        ? null
        : deltas.length.isOdd
        ? deltas[middle]
        : (deltas[middle - 1] + deltas[middle]) / 2,
    'candidate_lower': deltas.where((n) => n < 0).length,
    'equal': deltas.where((n) => n == 0).length,
    'candidate_higher': deltas.where((n) => n > 0).length,
  };
}
