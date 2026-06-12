import 'package:steward_cli/src/validation/claim_validator.dart';
import 'package:test/test.dart';

void main() {
  const validator = ClaimValidator();

  test('stewardship_protocol passes with protocol evidence', () {
    final result = validator.check(
      claim: 'stewardship_protocol',
      evidenceText: '''
status: stewardship_protocol
mode rules exist
memory boundaries exist
handoff rules exist
evidence gates exist
non-claims are documented
''',
    );

    expect(result.valid, isTrue);
    expect(result.diagnostics, isEmpty);
    expect(result.nonClaims, isNotEmpty);
    expect(result.toJson()['result'], 'not_rejected');
    expect(result.toJson()['accepted'], isFalse);
  });

  test('proven_repo_steward fails without with and without comparison', () {
    final result = validator.check(
      claim: 'proven_repo_steward',
      evidenceText:
          'The steward felt helpful and improved decisions in one session.',
    );

    expect(result.valid, isFalse);
    expect(result.toJson()['result'], 'rejected');
    expect(result.toJson()['accepted'], isFalse);
    expect(
      result.diagnostics,
      contains('missing evidence term: with continuity'),
    );
    expect(
      result.diagnostics,
      contains('missing evidence term: without continuity'),
    );
  });

  test('fully_adopted fails for green validation note alone', () {
    final result = validator.check(
      claim: 'fully_adopted',
      evidenceText: 'pnpm run validate passed.',
    );

    expect(result.valid, isFalse);
    expect(
      result.diagnostics,
      contains('missing evidence term: held_out_benchmarks'),
    );
    expect(
      result.diagnostics,
      contains('missing evidence term: observed_effect'),
    );
  });

  test('harness_ready fails for durability blocked evidence', () {
    final result = validator.check(
      claim: 'harness_ready',
      evidenceText: '''
doctor passed
actions list passed
action inspect passed
probe passed
benchmark result: "pass"
durability_blocked
''',
    );

    expect(result.valid, isFalse);
    expect(
      result.diagnostics,
      contains(
        'harness_ready cannot pass from blocked or durability_blocked evidence.',
      ),
    );
  });

  test('sub_steward fails without distinct continuity proof', () {
    final result = validator.check(
      claim: 'sub_steward',
      evidenceText:
          'Create one per package because every package could have a voice.',
    );

    expect(result.valid, isFalse);
    expect(result.diagnostics, contains('missing evidence term: root steward'));
    expect(
      result.diagnostics,
      contains('missing evidence term: distinct continuity'),
    );
  });

  test('not rejected never means accepted proof', () {
    final result = validator.check(
      claim: 'stewardship_protocol',
      evidenceText: '''
stewardship_protocol
mode memory handoff evidence non-claims
''',
    );

    expect(result.valid, isTrue);
    expect(result.toJson()['result'], 'not_rejected');
    expect(result.toJson()['accepted'], isFalse);
    expect(
      result.nonClaims,
      contains(
        'A not_rejected result only means this negative gate did not find obvious overclaim terms.',
      ),
    );
  });
}
