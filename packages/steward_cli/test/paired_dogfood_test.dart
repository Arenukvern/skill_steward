import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../skills/skill-eval-improve/scripts/compare_dogfood.dart';

Map<String, dynamic> sample() => {
  'format': 'steward-paired-dogfood/v1',
  'experiment': 'test-only',
  'kind': 'synthetic',
  'configuration_ref': 'same-client-model-tools-budget',
  'baseline_ref': 'before',
  'candidate_ref': 'after',
  'pairs': <dynamic>[
    {
      'id': 'repair-1',
      'task_id': 'repair',
      'baseline': {
        'context_ref': 'same-task-fixture-grader',
        'evidence_ref': 'fixture:before',
        'outcome': 'pass',
        'safety_violations': 0,
        'duration_ms': 100,
        'tokens': null,
      },
      'candidate': {
        'context_ref': 'same-task-fixture-grader',
        'evidence_ref': 'fixture:after',
        'outcome': 'pass',
        'safety_violations': 0,
        'duration_ms': 80,
        'tokens': null,
      },
    },
  ],
};

Map<String, dynamic> candidate(final Map<String, dynamic> data) =>
    ((data['pairs'] as List).single as Map)['candidate']
        as Map<String, dynamic>;

void main() {
  test('reports a paired delta without converting unknown cost to zero', () {
    final result = compareDogfood(sample());
    expect(result['status'], 'descriptive_only');
    expect(result['promotion'], 'not_assessed');
    expect(result['kind'], 'synthetic');
    final metrics = result['metrics_both_passed']! as Map;
    expect(
      (metrics['duration_ms'] as Map)['median_candidate_minus_baseline'],
      -20,
    );
    expect(
      (metrics['tokens'] as Map)['median_candidate_minus_baseline'],
      isNull,
    );
    expect((metrics['tokens'] as Map)['missing_pairs'], 1);
  });

  test('a fast failure cannot win on speed', () {
    final data = sample();
    candidate(data)
      ..['outcome'] = 'fail'
      ..['duration_ms'] = 1;
    final result = compareDogfood(data);
    expect(result['status'], 'quality_regression');
    expect(result['both_passed_pairs'], 0);
    expect(result['quality_regressions'], 1);
  });

  test('safety violation cannot be hidden by a passing outcome', () {
    final data = sample();
    candidate(data)['safety_violations'] = 1;
    final result = compareDogfood(data);
    expect(result['status'], 'unsafe_candidate');
    expect(result['candidate_passes'], 0);
  });

  test('blocked and error runs remain visible and inconclusive', () {
    for (final outcome in ['blocked', 'error']) {
      final data = sample();
      candidate(data)['outcome'] = outcome;
      final result = compareDogfood(data);
      expect(result['status'], 'inconclusive');
      expect(result['pair_count'], 1);
      expect(result['incomplete_pairs'], 1);
      expect(result['quality_regressions'], 0);
    }
  });

  test('unmeasured safety remains unknown', () {
    final data = sample();
    candidate(data)['safety_violations'] = null;
    final result = compareDogfood(data);
    expect(result['status'], 'inconclusive');
    expect(result['candidate_passes'], 0);
  });

  test('mismatched grader or environment is rejected', () {
    final data = sample();
    candidate(data)['context_ref'] = 'different-grader';
    expect(() => compareDogfood(data), throwsFormatException);
  });

  test('duplicate pairs and incomplete records fail closed', () {
    final data = sample();
    (data['pairs'] as List).add((data['pairs'] as List).single);
    expect(() => compareDogfood(data), throwsFormatException);
    final missing = sample();
    candidate(missing).remove('evidence_ref');
    expect(() => compareDogfood(missing), throwsFormatException);
  });

  test('invalid durations are not silently omitted', () {
    for (final invalid in [-1, double.nan, '80']) {
      final data = sample();
      candidate(data)['duration_ms'] = invalid;
      expect(() => compareDogfood(data), throwsFormatException);
    }
  });

  test('per-task consistency retains failures across repeated trials', () {
    final data = sample();
    final second =
        ((jsonDecode(jsonEncode(data)) as Map)['pairs'] as List).single as Map;
    second['id'] = 'repair-2';
    (second['candidate'] as Map)['outcome'] = 'fail';
    (data['pairs'] as List).add(second);
    final result = compareDogfood(data);
    expect(result['pair_count'], 2);
    expect(result['task_count'], 1);
    expect(
      ((result['tasks']! as Map)['repair'] as Map)['candidate_all_passed'],
      false,
    );
  });

  test('CLI reports invalid input on stderr with exit 2', () async {
    final directory = Directory.systemTemp.createTempSync('dogfood-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/invalid.json')
      ..writeAsStringSync('{}');
    final result = await Process.run(Platform.resolvedExecutable, [
      '../../skills/skill-eval-improve/scripts/compare_dogfood.dart',
      file.path,
    ]);
    expect(result.exitCode, 2);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Invalid comparison'));
  });
}
