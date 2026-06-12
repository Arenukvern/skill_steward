import 'package:steward_cli/src/validation/protocol_validator.dart';
import 'package:test/test.dart';

void main() {
  const validator = ProtocolValidator();

  test('valid mode event passes', () {
    expect(validator.validateModeEvent(validModeEvent()), isEmpty);
  });

  test('mode event missing non_claims fails', () {
    final event = validModeEvent()..remove('non_claims');

    expect(
      validator.validateModeEvent(event),
      contains('non_claims must be an array of strings.'),
    );
  });

  test('mode event rejects status stronger than tool execution mode', () {
    final event = validModeEvent()..['status'] = 'proven_repo_steward';

    expect(
      validator.validateModeEvent(event),
      contains(
        'mode/status mismatch: tool-execution may only record stewardship_protocol status.',
      ),
    );
  });

  test('delegation mode requires delegated surface', () {
    final event = validModeEvent()
      ..['mode'] = 'delegation'
      ..remove('delegated_surface');

    expect(
      validator.validateModeEvent(event),
      contains('delegation mode requires delegated_surface.'),
    );
  });

  test('mode event rejects unknown keys instead of hiding memory', () {
    final event = validModeEvent()..['raw_memory'] = 'private chat excerpt';

    expect(
      validator.validateModeEvent(event),
      contains('raw_memory is not an allowed mode event field.'),
    );
  });

  test('self-model requires provenance and privacy policy fields', () {
    final diagnostics = validator.validateSelfModel(validSelfModel());

    expect(diagnostics, isEmpty);
  });

  test('self-model rejects unknown keys instead of hiding memory', () {
    final selfModel = validSelfModel()
      ..['relational_memory_raw'] = 'private chat excerpt';

    expect(
      validator.validateSelfModel(selfModel),
      contains('relational_memory_raw is not an allowed self-model field.'),
    );
  });

  test(
    'self-model with proven status needs structured proof and non-claims',
    () {
      final selfModel = validSelfModel()
        ..['status'] = 'proven_repo_steward'
        ..['non_claims'] = <String>[];

      final diagnostics = validator.validateSelfModel(selfModel);

      expect(
        diagnostics,
        contains('validation is required before claiming proven_repo_steward.'),
      );
      expect(
        diagnostics,
        contains('non_claims must contain at least 1 item(s).'),
      );
    },
  );

  test('proven status rejects loose validation evidence strings', () {
    final selfModel = validSelfModel()
      ..['status'] = 'proven_repo_steward'
      ..['validation'] = {
        'evidence': ['looked useful once'],
      };

    final diagnostics = validator.validateSelfModel(selfModel);

    expect(
      diagnostics,
      contains('validation.tasks must be an array of objects.'),
    );
    expect(
      diagnostics,
      contains(
        'validation.comparison must describe with and without continuity results.',
      ),
    );
  });

  test('forbidden private material fails', () {
    expect(
      validator.validateNoRawPrivateMaterial('OPENAI_API_KEY=secret'),
      contains('contains forbidden private material marker: OPENAI_API_KEY'),
    );
  });
}

Map<String, dynamic> validModeEvent() => {
  'schema': 'steward/mode-event/v1',
  'id': 'mode-2026-06-12-protocol-smoke',
  'created_at': '2026-06-12T00:00:00Z',
  'repo': 'skill_steward',
  'mode': 'tool-execution',
  'status': 'stewardship_protocol',
  'intent':
      'Validate protocol artifact shape without entering steward presence.',
  'delegated_surface': 'steward protocol validate',
  'evidence_bar': 'schema-valid protocol smoke only',
  'boundary_signals': ['no H4 claim'],
  'self_model_pointer': '.steward/self-model.example.json',
  'non_claims': ['Does not prove steward_presence or proven_repo_steward.'],
};

Map<String, dynamic> validSelfModel() => {
  'schema': 'steward/self-model/v1',
  'steward_id': 'skill-steward-protocol',
  'repo': 'skill_steward',
  'status': 'stewardship_protocol',
  'identity_role': 'Protocol continuity artifact, not final authority.',
  'boundary_awareness': ['Tool output stays separate from steward synthesis.'],
  'open_questions': ['What evidence would change this status?'],
  'values_in_action': ['Evidence before status claims.'],
  'reflective_state':
      'Protocol shape is declared; steward status is not proven.',
  'trigger_event_id': 'mode-2026-06-12-protocol-smoke',
  'consent_basis': 'repo-governance-artifact',
  'visibility': 'repo-reviewable',
  'retention': 'until superseded by later governance artifact',
  'redaction_policy': 'no raw chats, secrets, credentials, or private memory',
  'non_claims': ['Does not prove consciousness or repo steward status.'],
};
