import 'package:json_annotation/json_annotation.dart';
import 'package:steward_cli/src/contracts/claim_contracts.dart';
import 'package:steward_cli/src/contracts/protocol_contracts.dart';
import 'package:steward_cli/src/contracts/schema_contracts.dart';
import 'package:steward_cli/src/validation/json_schema_subset.dart';
import 'package:test/test.dart';

void main() {
  test('claim check payload round-trips with stable public fields', () {
    final payload = ClaimCheckPayload(
      claim: 'stewardship_protocol',
      valid: true,
      diagnostics: const [],
      nonClaims: const [
        'Claim checks are negative gates; they do not accept or award steward status.',
      ],
    );

    final json = payload.toJson();
    expect(json, {
      'schema_version': 'steward.claim.check.v1',
      'claim': 'stewardship_protocol',
      'valid': true,
      'result': 'not_rejected',
      'accepted': false,
      'diagnostics': [],
      'non_claims': [
        'Claim checks are negative gates; they do not accept or award steward status.',
      ],
    });
    expect(ClaimCheckPayload.fromJson(json).toJson(), json);
  });

  test('claim check payload rejects unknown JSON fields', () {
    expect(
      () => ClaimCheckPayload.fromJson({
        'schema_version': 'steward.claim.check.v1',
        'claim': 'stewardship_protocol',
        'valid': true,
        'result': 'not_rejected',
        'accepted': false,
        'diagnostics': <String>[],
        'non_claims': <String>[],
        'extra': true,
      }),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('mode event payload rejects invalid enum values', () {
    expect(
      () => ModeEventContract.fromJson({
        'schema': 'steward/mode-event/v1',
        'id': 'mode-1',
        'created_at': '2026-06-12T00:00:00Z',
        'repo': 'skill_steward',
        'mode': 'personality-wrapper',
        'status': 'stewardship_protocol',
        'intent': 'test enum rejection',
        'evidence_bar': 'schema-only',
        'non_claims': ['not proof'],
      }),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });

  test('schema validate payload validates against generated schema subset', () {
    const payload = SchemaValidatePayload(
      root: '/tmp/repo',
      schema: 'self-model',
      file: '.steward/self-model.json',
      valid: true,
      diagnostics: [],
    );

    final result = validateJsonSchemaSubset(
      payload.toJson(),
      generatedStewardSchema('schema-validate'),
    );

    expect(result.valid, isTrue);
    expect(result.diagnostics, isEmpty);
  });
}
