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
  });
}
