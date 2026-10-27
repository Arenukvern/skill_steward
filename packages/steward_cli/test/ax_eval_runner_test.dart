import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/eval/ax_eval_runner.dart';
import 'package:steward_cli/src/eval/ax_skill_router.dart';
import 'package:test/test.dart';

void main() {
  late String repoRoot;

  setUpAll(() {
    final candidates = [
      Directory.current,
      Directory(p.normalize(p.join(Directory.current.path, '..', '..'))),
    ];
    for (final dir in candidates) {
      if (Directory(p.join(dir.path, 'skills', 'repo-quality-system-lifecycle'))
          .existsSync()) {
        repoRoot = dir.path;
        return;
      }
    }
    fail('Could not find skill_steward repo root from ${Directory.current.path}');
  });

  test('loads AX cases and runs description router', () async {
    final cases = await loadAxCases(p.join(repoRoot, 'evals', 'cases'));
    expect(cases.length, greaterThanOrEqualTo(35));
    final profiles = await loadSkillRoutingProfiles(p.join(repoRoot, 'skills'));
    expect(profiles.length, 6);

    final product = routePrompt(
      'Ship the checkout button color change the PM asked for today.',
      profiles,
    );
    expect(product.skill, 'none');

    final report = await runAxEvalSuite(repoRoot);
    expect(report.cases.length, cases.length);
    expect(report.measurement, contains('not live agent'));
  });

  test('baseline writer is deterministic across runs', () async {
    final baseline = await runAxBaseline(repoRoot);
    expect(baseline['runs'], 3);
    expect(baseline['deterministic'], isTrue);
    final signals = baseline['signals_per_run'] as List<dynamic>;
    expect(signals.length, 3);
  });

  test('stage history baseline keeps stages map', () async {
    final raw = await File(
      p.join(repoRoot, 'evals', 'baselines', 'ax-2026-10-27.json'),
    ).readAsString();
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final stages = doc['stages'] as Map<String, dynamic>;
    expect(stages.keys, containsAll(['before', 'after_routing', 'after_compress']));
  });
}
