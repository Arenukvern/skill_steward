import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/repo_root.dart';
import 'package:steward_cli/src/validation/validation.dart';
import 'package:test/test.dart';

/// Simple expectation record for fixture-based validation tests.
/// Uses string fragments for robust matching against error/warning messages
/// (avoids brittle full-string or unicode copy issues).
typedef FixtureExpectation = ({
  List<String> errorContains,
  List<String> warningContains,
});

/// Expected behaviors for each fixture under evals/fixtures/validate/
/// as documented in evals/fixtures/validate/README.md.
final Map<String, FixtureExpectation> _expectations = {
  'good-skill': (errorContains: [], warningContains: []),
  'bad-name-mismatch': (
    errorContains: ['must match directory'],
    warningContains: ['Missing references/sources.md'],
  ),
  'invalid-name-format': (
    errorContains: ['invalid: use lowercase', 'must match directory'],
    warningContains: ['Missing references/sources.md'],
  ),
  'missing-frontmatter': (
    errorContains: ['Missing YAML frontmatter'],
    warningContains: [],
  ),
  'missing-sources': (
    errorContains: [],
    warningContains: ['Missing references/sources.md'],
  ),
  'has-readme': (
    errorContains: [],
    warningContains: [
      'Missing references/sources.md',
      'README.md in skill folder is ignored',
    ],
  ),
  'too-long-body': (
    errorContains: [],
    warningContains: ['SKILL.md is ~', 'Missing references/sources.md'],
  ),
  // New fixtures added during parallel evals expansion
  'very-short-body': (
    errorContains: [],
    warningContains: ['SKILL.md body is very short'],
  ),
  'missing-skill-md': (
    errorContains: ['Missing required file SKILL.md'],
    warningContains: [],
  ),
  'registry-drift': (
    errorContains: [],
    // Registry warnings are only produced by validateAllSkills (when the registry is loaded).
    // validateSingleSkill on this fixture produces no registry warning.
    warningContains: [],
  ),
  'missing-description': (
    errorContains: ['Missing required frontmatter field: description'],
    warningContains: [],
  ),
  'missing-license': (
    errorContains: [],
    warningContains: ['Missing frontmatter field: license'],
  ),
  'invalid-yaml-compact-mapping': (
    errorContains: ['Invalid YAML frontmatter'],
    warningContains: [],
  ),
};

void main() {
  // Resolve fixtures robustly for test execution contexts:
  // - `cd packages/steward_cli && dart test` (Directory.current works, script may be in dart cache)
  // - direct `dart test test/...` or IDE launches (current or script dir)
  // Walks using the package's findRepoRoot helper which looks for skills.sh.json marker.
  late final String fixturesRoot;

  setUpAll(() {
    String findRootForTest() {
      // Prefer CWD first — this is where `dart test` is normally invoked from package dir.
      try {
        return findRepoRoot(Directory.current);
      } on Object {
        // Fallback to on-disk script location (works when running from source tree directly).
        final scriptPath = Platform.script.toFilePath();
        final scriptStart = File(scriptPath).parent;
        return findRepoRoot(scriptStart);
      }
    }

    final repoRoot = findRootForTest();
    fixturesRoot = p.join(repoRoot, 'evals', 'fixtures', 'validate');
  });

  group('Dart validation module (validateSingleSkill / validateAllSkills)', () {
    test('discovers all documented fixtures', () {
      final dir = Directory(fixturesRoot);
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'Fixtures dir must exist for tests',
      );

      final entries = dir.listSync();
      final subdirs =
          entries
              .whereType<Directory>()
              .map((final d) => p.basename(d.path))
              .where((final name) => !name.startsWith('.'))
              .toList()
            ..sort();

      // Must include all fixtures we have expectations for.
      expect(subdirs, containsAll(_expectations.keys));
      // We do not assert exact count here to remain resilient as fixture set grows.
    });

    // One test case per fixture using the expectations map.
    // This is resilient as new fixtures are added.
    for (final fixture in _expectations.keys) {
      test('validateSingleSkill on $fixture matches documented expectations', () async {
        final fixturePath = p.join(fixturesRoot, fixture);
        final result = await validateSingleSkill(fixturePath, fixture);

        final exp = _expectations[fixture]!;
        for (final fragment in exp.errorContains) {
          expect(
            result.errors.any((final e) => e.contains(fragment)),
            isTrue,
            reason:
                'Fixture "$fixture" — expected an error containing "$fragment". '
                'Actual errors: ${result.errors}',
          );
        }
        expect(
          result.errors,
          hasLength(exp.errorContains.length),
          reason:
              'Fixture "$fixture" should have exactly ${exp.errorContains.length} errors',
        );

        for (final fragment in exp.warningContains) {
          expect(
            result.warnings.any((final w) => w.contains(fragment)),
            isTrue,
            reason:
                'Fixture "$fixture" — expected a warning containing "$fragment". '
                'Actual warnings: ${result.warnings}',
          );
        }
        expect(
          result.warnings,
          hasLength(exp.warningContains.length),
          reason:
              'Fixture "$fixture" should have exactly ${exp.warningContains.length} warnings',
        );

        // isValid is purely error-driven (per validation_result.dart)
        expect(result.isValid, result.errors.isEmpty);
        expect(result.dirName, fixture);
      });
    }

    test(
      'validateAllSkills on fixtures directory produces correct aggregate report',
      () async {
        final report = await validateAllSkills(fixturesRoot);

        // There are failing skills (name/format/frontmatter errors)
        expect(report.ok, isFalse);
        // Should have at least as many skills as we have expectations for.
        expect(
          report.skills.length,
          greaterThanOrEqualTo(_expectations.length),
        );

        final allNames = report.skills.map((final s) => s.dirName).toSet();
        expect(allNames, containsAll(_expectations.keys));

        final failed = report.failed.map((final s) => s.dirName).toSet();
        expect(
          failed,
          containsAll({
            'bad-name-mismatch',
            'invalid-name-format',
            'missing-frontmatter',
            'invalid-yaml-compact-mapping',
          }),
        );

        // Successful ones (only warnings or clean) among the baseline
        final okOnes = report.skills
            .where((final s) => s.isValid)
            .map((final s) => s.dirName)
            .toSet();
        expect(
          okOnes,
          containsAll({
            'good-skill',
            'missing-sources',
            'has-readme',
            'too-long-body',
            'missing-license',
          }),
        );

        // Spot-check one aggregate result (via the all-skills path).
        // Singles tests already verified direct validateSingleSkill on good-skill is clean.
        // The all path now also runs registry checks (see skills.sh.json), so individual
        // results obtained here may carry registry-related warnings for unregistered fixture dirs.
        final good = report.skills.firstWhere(
          (final s) => s.dirName == 'good-skill',
        );
        expect(good.errors, isEmpty);
        // registryWarnings on the report (or per-skill) are expected to be populated for this input.
        expect(report.registryWarnings, isNotEmpty);
      },
    );

    test('validateAllSkills fails invalid central steward.yaml', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'steward_validate_all_contract_',
      );
      try {
        _writeValidSkillStewardFixture(tempDir.path, 'contract-check');
        await _writeInvalidStewardConfig(tempDir.path);

        final report = await validateAllSkills(p.join(tempDir.path, 'skills'));

        expect(report.ok, isFalse);
        expect(
          report.groups['repoContract']?.warnings,
          contains(
            'actions.invalid.local.outputs: outputs must contain at least one output record.',
          ),
        );
        expect(
          report.groups['registry']?.warnings,
          isNot(
            contains(
              'actions.invalid.local.outputs: outputs must contain at least one output record.',
            ),
          ),
        );
        final groupsJson = report.toJson()['groups'] as Map<String, dynamic>;
        expect(
          (groupsJson['repoContract'] as Map<String, dynamic>)['warnings'],
          contains(
            'actions.invalid.local.outputs: outputs must contain at least one output record.',
          ),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('split validation lanes isolate failure ownership', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'steward_validate_split_lanes_',
      );
      try {
        _writeValidSkillStewardFixture(tempDir.path, 'lane-check');
        await File(p.join(tempDir.path, 'skills.sh.json')).writeAsString('''
{
  "skills": ["lane-check", "missing-registry-skill"]
}
''');
        await _writeInvalidStewardConfig(tempDir.path);
        _writeAdoptionRunRecord(
          tempDir.path,
          attempts: 2,
          returnToGoalStep: '',
          outcomeDecision: 'promote',
          claimedLevel: 'H2',
          canPromoteInThisRun: true,
        );

        final skillsDir = p.join(tempDir.path, 'skills');
        final skills = await validateSkillsDirectory(skillsDir);
        final registry = await validateSkillRegistry(skillsDir);
        final repoContract = await validateRepoContract(tempDir.path);
        final evidence = await validateEvidence(tempDir.path);
        final all = await validateAllSkills(skillsDir);

        expect(skills.ok, isTrue);
        expect(skills.groups.keys, contains('skills'));
        expect(skills.groups.keys, isNot(contains('registry')));

        expect(
          registry.groups['registry']?.warnings,
          contains(
            'skills.sh.json references "missing-registry-skill" but no matching skill directory found',
          ),
        );
        expect(
          registry.groups['registry']?.warnings,
          everyElement(isNot(contains('outputs must contain'))),
        );

        expect(
          repoContract.groups['repoContract']?.warnings,
          contains(
            'actions.invalid.local.outputs: outputs must contain at least one output record.',
          ),
        );
        expect(
          evidence.groups['evidence']?.warnings,
          contains(contains('tool_detour.attempts >= 2')),
        );

        expect(
          all.groups.keys,
          containsAll(['skills', 'registry', 'repoContract', 'evidence']),
        );
        expect(all.ok, isFalse);
        expect(
          all.groups['repoContract']?.warnings,
          contains(
            'actions.invalid.local.outputs: outputs must contain at least one output record.',
          ),
        );
        expect(
          all.groups['evidence']?.warnings,
          contains(contains('tool_detour.attempts >= 2')),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('adoption-run/v2 evidence validator', () {
      test('accepts a valid template-shaped record', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_valid_',
        );
        try {
          _writeAdoptionRunRecord(tempDir.path);

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(diagnostics, isEmpty);
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires stop semantics after two tool repair attempts', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_detour_',
        );
        try {
          _writeAdoptionRunRecord(
            tempDir.path,
            attempts: 2,
            returnToGoalStep: '',
            outcomeDecision: 'promote',
            claimedLevel: 'H2',
            canPromoteInThisRun: true,
          );

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(
              contains(
                'tool_detour.attempts >= 2 requires stop_rule_triggered: true',
              ),
            ),
          );
          expect(
            diagnostics,
            contains(
              contains(
                'tool_detour.attempts >= 2 requires a non-empty return_to_goal_step',
              ),
            ),
          );
          expect(
            diagnostics,
            contains(contains('outcome.decision must not be promote')),
          );
          expect(
            diagnostics,
            contains(
              contains('promotion.can_promote_in_this_run must be false'),
            ),
          );
          expect(
            diagnostics,
            contains(contains('promotion.claimed_level must stay none')),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires observed effect to avoid false-green proof', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_effect_',
        );
        try {
          _writeAdoptionRunRecord(tempDir.path, observedEffect: '');

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(contains('hot_path_claim.observed_effect is required')),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires product impact line before success claims', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_product_impact_',
        );
        try {
          _writeAdoptionRunRecord(tempDir.path, productImpactLine: '');

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(contains('outcome.product_impact_line is required')),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires recognized product impact prefix', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_product_impact_prefix_',
        );
        try {
          _writeAdoptionRunRecord(
            tempDir.path,
            productImpactLine:
                'product_surface: old taxonomy line; proof: tool/check.sh passed',
          );

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(
              contains(
                'outcome.product_impact_line must start with one recognized prefix',
              ),
            ),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('accepts recognized product impact prefixes', () async {
        const prefixes = [
          'runtime_behavior:',
          'public_api:',
          'product_native_gate:',
          'visual_capture:',
          'performance_metric:',
          'release_path:',
          'developer_workflow:',
          'command_output:',
          'plugin_install:',
          'support_only:',
        ];

        for (final prefix in prefixes) {
          final tempDir = Directory.systemTemp.createTempSync(
            'steward_adoption_run_product_impact_prefix_ok_',
          );
          try {
            final impactLine = prefix == 'support_only:'
                ? '$prefix Steward scaffolding only; proof: tool/check.sh passed'
                : '$prefix observed product impact; proof: tool/check.sh passed';
            _writeAdoptionRunRecord(
              tempDir.path,
              productImpactLine: impactLine,
            );

            final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

            expect(diagnostics, isEmpty, reason: prefix);
          } finally {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test('support-only impact cannot promote', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_support_only_',
        );
        try {
          _writeAdoptionRunRecord(
            tempDir.path,
            productImpactLine:
                'support_only: Steward evals became greener; no product surface changed.',
            outcomeDecision: 'promote',
            claimedLevel: 'H2',
            canPromoteInThisRun: true,
          );

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(
              contains(
                'outcome.decision must not be promote when product_impact_line is support_only',
              ),
            ),
          );
          expect(
            diagnostics,
            contains(
              contains(
                'promotion.can_promote_in_this_run must be false when product_impact_line is support_only',
              ),
            ),
          );
          expect(
            diagnostics,
            contains(
              contains(
                'promotion.claimed_level must stay none when product_impact_line is support_only',
              ),
            ),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires declared surfaces before raw exploration', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_surfaces_',
        );
        try {
          _writeAdoptionRunRecord(
            tempDir.path,
            declaredSurfacesUsedFirst: const [],
          );

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(
              contains(
                'direct_problem_path.declared_surfaces_used_first must name at least one declared surface',
              ),
            ),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires repeated and held-out proof for H5/S5', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_h5_',
        );
        try {
          _writeAdoptionRunRecord(
            tempDir.path,
            claimedLevel: 'H5',
            repeatedEvidence: ['first-proof'],
          );

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(
              contains('requires at least two repeated_evidence entries'),
            ),
          );
          expect(
            diagnostics,
            contains(contains('requires held_out_benchmarks')),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('requires broad evidence for repo maturity claims', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'steward_adoption_run_repo_maturity_',
        );
        try {
          _writeAdoptionRunRecord(
            tempDir.path,
            scope: 'repo_maturity',
            broadEvidence: [],
          );

          final diagnostics = await validateAdoptionRunEvidence(tempDir.path);

          expect(
            diagnostics,
            contains(
              contains(
                'capability.scope repo_maturity requires promotion.broad_evidence',
              ),
            ),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });
    });
  });
}

void _writeValidSkillStewardFixture(final String rootPath, final String name) {
  File(p.join(rootPath, 'skills.sh.json')).writeAsStringSync('''
{
  "skills": ["$name"]
}
''');
  final skillDir = Directory(p.join(rootPath, 'skills', name))
    ..createSync(recursive: true);
  File(p.join(skillDir.path, 'SKILL.md')).writeAsStringSync('''
---
name: $name
description: Checks split validation ownership.
license: MIT
type: governance
---

Use this fixture to prove validation lanes report their own diagnostics.
''');
  Directory(p.join(skillDir.path, 'references')).createSync();
  File(
    p.join(skillDir.path, 'references', 'sources.md'),
  ).writeAsStringSync('- local fixture\n');
}

Future<void> _writeInvalidStewardConfig(final String rootPath) async {
  await File(p.join(rootPath, 'steward.yaml')).writeAsString('''
schema: steward/v1
repo: {id: contract_fixture}
stewardship:
  governance: {north_star: AGENTS.md}
  knowledge: {docs_map: AGENTS.md}
  skill_lifecycle: {installable_skills: true}
  quality: {validate: steward validate}
  harness: {enabled: true}
  release: {changelog: CHANGELOG.md}
  review_handoff: {moe_required_for_architecture: true}
  strategic_alignment: {vision_source: AGENTS.md}
  security: {action_effects: required}
  org: {owners: AGENTS.md}
actions:
  invalid.local:
    kind: command
    desc: Invalid action with explicit empty outputs.
    command: {argv: [steward, doctor, --json], shell: false}
    effects:
      fs_read: ["."]
      fs_write: []
      git: false
      network: false
      secrets: false
      destructive: false
    safety:
      class: observe
      default_policy: auto
      requires_confirmation: false
    outputs: []
probes:
  quick: {actions: [invalid.local]}
''');
}

void _writeAdoptionRunRecord(
  final String rootPath, {
  final int attempts = 0,
  final bool stopRuleTriggered = false,
  final String returnToGoalStep = 'Returned to the original native gate.',
  final String outcomeDecision = 'continue',
  final String claimedLevel = 'none',
  final bool canPromoteInThisRun = false,
  final String scope = 'capability_level',
  final List<String> repeatedEvidence = const [],
  final List<String> heldOutBenchmarks = const [],
  final List<String> broadEvidence = const [],
  final List<String> declaredSurfacesUsedFirst = const ['AGENTS.md'],
  final String observedEffect =
      'Future agents can identify the native gate result.',
  final String productImpactLine =
      'product_native_gate: native gate result; proof: tool/check.sh passed',
}) {
  final evidenceDir = Directory(p.join(rootPath, 'docs', 'evidence'))
    ..createSync(recursive: true);
  File(p.join(evidenceDir.path, 'adoption-run.mdx')).writeAsStringSync('''
# Adoption run

```yaml
schema: steward/adoption-run/v2
run:
  repo: sample_repo
  subject_commit: clean
  date: "2026-06-10"
  agent_context: fresh-agent
user_goal:
  prompt: "Prove the bounded workflow."
  requested_outcome: "A useful workflow passes."
  acceptance_check: "The native gate passes."
  status: solved
  evidence:
    - "native gate passed"
capability:
  id: sample.capability
  class: native_gate
  scope: $scope
  user_value: "Future agents get a shorter path."
  native_owner: tool/check.sh
  pattern_layer: native
  maintenance_delta: reduced
direct_problem_path:
  declared_surfaces_used_first: ${_yamlStringList(declaredSurfacesUsedFirst)}
  native_gates_run:
    - tool/check.sh
  raw_shell_reason: ""
tool_detour:
  needed: ${attempts > 0}
  reason: "${attempts > 0 ? 'Tool setup failed.' : ''}"
  attempts: $attempts
  artifacts_created: []
  stop_rule_triggered: $stopRuleTriggered
  return_to_goal_step: "$returnToGoalStep"
generational_architecture_check:
  repeated_pattern: false
  smaller_layer_considered: true
  deletion_or_collapse_option: "Keep the native gate."
  promotion_guard: "Repeat on a held-out task."
  why_this_layer: "Native gate is enough."
outcome:
  decision: $outcomeDecision
  reason: "This serves the user goal."
  product_impact_line: "$productImpactLine"
  docs_or_adr_destination: none
hot_path_claim:
  problem_class: "native gate proof"
  created_surface: "none"
  falsifier: "broken fixture"
  positive_proof: "tool/check.sh passed"
  observed_effect: "$observedEffect"
  held_out_or_future_task: "future agent repeats gate"
  non_claims:
    - "Does not prove broad repo maturity."
promotion:
  claimed_level: $claimedLevel
  can_promote_in_this_run: $canPromoteInThisRun
  review_required: true
  repeated_evidence: ${_yamlStringList(repeatedEvidence)}
  held_out_benchmarks: ${_yamlStringList(heldOutBenchmarks)}
  broad_evidence: ${_yamlStringList(broadEvidence)}
```
''');
}

String _yamlStringList(final List<String> values) {
  if (values.isEmpty) return '[]';
  return '[${values.map((final value) => '"$value"').join(', ')}]';
}
