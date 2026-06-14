import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/schema_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    exitCode = 0;
    tempDir = Directory.systemTemp.createTempSync('steward_schema_emit_test_');
    File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsStringSync(jsonEncode({'skills': []}));
    File(p.join(tempDir.path, 'steward.yaml')).writeAsStringSync('''
schema: steward/v1
repo:
  id: sample_repo
  archetype: cli_tool
harness:
  name: steward
  mode: cli
adoption:
  status: adopting
stewardship:
  governance: {charter: AGENTS.md}
  knowledge: {docs_map: AGENTS.md}
  repo_quality: {contract_spec: steward.yaml}
actions: {}
probes: {}
diagnostics: {cases: {}}
unknown_cases: {path: .steward/unknown-cases/}
provenance: {dependencies: [], artifacts: [], benchmarks: []}
''');
    final schemaDir = Directory(p.join(tempDir.path, 'docs', 'schemas'))
      ..createSync(recursive: true);
    File(
      p.join(schemaDir.path, 'schema-validate-v1.schema.json'),
    ).writeAsStringSync(
      jsonEncode({
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
        'type': 'object',
        'required': [
          'schema_version',
          'root',
          'schema',
          'file',
          'valid',
          'diagnostics',
        ],
        'properties': {
          'schema_version': {'const': 'steward.schema.validate.v1'},
          'root': {'type': 'string'},
          'schema': {'type': 'string'},
          'valid': {'type': 'boolean'},
          'diagnostics': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'additionalProperties': false,
      }),
    );
  });

  tearDown(() {
    exitCode = 0;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('schema emit prints generated schema for contract payload', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SchemaCommand(buffer, tempDir));

    await runner.run([
      'schema',
      'emit',
      '--schema',
      'schema-validate',
      '--source',
      'generated',
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['schema_version'], 'steward.schema.emit.v1');
    expect(payload['schema'], 'schema-validate');
    expect(payload['source'], 'generated');
    expect(payload['valid'], isTrue);
    expect(
      (payload['json_schema'] as Map<String, dynamic>)['required'],
      contains('schema_version'),
    );
    expect(exitCode, 0);
  });

  test('schema drift detects checked-in schema mismatch', () async {
    final payload = await schemaDriftPayload(tempDir.path);
    expect(payload['schema_version'], 'steward.schema.drift.v1');
    expect(payload['valid'], isFalse);
    expect(payload['checks'], isNotEmpty);
    expect(payload['diagnostics'], contains(contains('schema-validate')));
  });
}
