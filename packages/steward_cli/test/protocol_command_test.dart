import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/protocol_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    exitCode = 0;
    tempDir = Directory.systemTemp.createTempSync('steward_protocol_test_');
    File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsStringSync(jsonEncode({'skills': []}));
  });

  tearDown(() {
    exitCode = 0;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('command JSON output reports invalid when files are missing', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ProtocolCommand(buffer, tempDir));

    await runner.run([
      'protocol',
      'validate',
      '--mode-events',
      '.steward/events.jsonl',
      '--self-model',
      '.steward/self-model.json',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;

    expect(payload['schema_version'], 'steward.protocol.validate.v1');
    expect(payload['valid'], isFalse);
    expect(payload['diagnostics'], isNotEmpty);
    expect(payload['files'], contains('mode_events'));
    expect(payload['files'], contains('self_model'));
    expect(exitCode, 1);
  });

  test('command validates mode events and self-model files', () async {
    final stewardDir = Directory(p.join(tempDir.path, '.steward'))
      ..createSync();
    File(
      p.join(stewardDir.path, 'events.jsonl'),
    ).writeAsStringSync('${jsonEncode(validModeEvent())}\n');
    File(
      p.join(stewardDir.path, 'self-model.json'),
    ).writeAsStringSync(jsonEncode(validSelfModel()));

    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(ProtocolCommand(buffer, tempDir));

    await runner.run([
      'protocol',
      'validate',
      '--mode-events',
      '.steward/events.jsonl',
      '--self-model',
      '.steward/self-model.json',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;

    expect(payload['valid'], isTrue);
    expect(payload['diagnostics'], isEmpty);
    expect((payload['files'] as Map)['mode_events'], containsPair('events', 1));
    expect(exitCode, 0);
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
