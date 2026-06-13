import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/doctor_command.dart';
import 'package:steward_cli/src/commands/dogfood_command.dart';
import 'package:steward_cli/src/commands/ecology_command.dart';
import 'package:steward_cli/src/commands/protocol_command.dart';
import 'package:steward_cli/src/commands/unknown_case_command.dart';
import 'package:steward_cli/src/validation/steward_config.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync(
      'steward_schema_payload_test_',
    );
    await File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsString(validStewardV1());
    Directory(
      p.join(tempDir.path, 'docs', 'evidence'),
    ).createSync(recursive: true);
    await File(
      p.join(tempDir.path, 'docs', 'evidence', 'current-dogfood-status.mdx'),
    ).writeAsString('''
---
status: current
evidence_type: ledger
claim_tested: Current narrow dogfood status.
proof_level: current ledger route
result: stewardship_protocol only
limitations: No maturity claim.
non_claims:
  - H5
---

# Current dogfood status
''');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'doctor payload conforms to doctor v1 schema top-level contract',
    () async {
      final result = await StewardConfig.loadChecked(tempDir.path);
      final payload = stewardDoctorPayload(tempDir.path, result);
      final schema = loadSchema('doctor-v1.schema.json');

      expect(
        payload.keys,
        containsAll([
          'schema_version',
          'root',
          'config',
          'repo',
          'harness',
          'stewardship_pillars',
          'diagnostics',
          'actions',
          'probes',
          'next_actions',
        ]),
      );
      expectSchemaConformance(payload, schema);
    },
  );

  test(
    'unknown-case payload conforms to unknown-case v1 schema top-level contract',
    () async {
      final observationFile = await writeObservationFixture(tempDir);
      final record = await createUnknownCasePayload(
        tempDir.path,
        p.relative(observationFile.path, from: tempDir.path),
      );
      final schema = loadSchema('unknown-case-v1.schema.json');

      expect(
        record.keys,
        containsAll([
          'schema',
          'id',
          'status',
          'repo',
          'created_at',
          'source_observation',
          'summary',
          'evidence',
          'review',
          'retention',
        ]),
      );
      expectSchemaConformance(record, schema);
    },
  );

  test('protocol example artifacts conform to protocol schemas', () {
    final repoRoot = p.normalize(p.join(Directory.current.path, '..', '..'));
    final modeEventsFile = File(
      p.join(repoRoot, '.steward/events.example.jsonl'),
    );
    final selfModelFile = File(
      p.join(repoRoot, '.steward/self-model.example.json'),
    );
    final modeEventSchema = loadSchema('mode-event-v1.schema.json');
    final selfModelSchema = loadSchema('self-model-v1.schema.json');

    for (final line in const LineSplitter().convert(
      modeEventsFile.readAsStringSync(),
    )) {
      if (line.trim().isEmpty) continue;
      expectSchemaConformance(
        jsonDecode(line) as Map<String, dynamic>,
        modeEventSchema,
      );
    }
    expectSchemaConformance(
      jsonDecode(selfModelFile.readAsStringSync()) as Map<String, dynamic>,
      selfModelSchema,
    );
  });

  test(
    'protocol validate payload exposes stable machine-readable shape',
    () async {
      final repoRoot = p.normalize(p.join(Directory.current.path, '..', '..'));
      final payload = await validateProtocolPayload(
        repoRoot,
        modeEventsPath: '.steward/events.example.jsonl',
        selfModelPath: '.steward/self-model.example.json',
      );

      expect(payload['schema_version'], 'steward.protocol.validate.v1');
      expect(payload['valid'], isTrue);
      expect(payload['diagnostics'], isEmpty);
      expect(payload['files'], isA<Map>());
      expect((payload['files'] as Map)['mode_events'], isA<Map>());
      expect((payload['files'] as Map)['self_model'], isA<Map>());
    },
  );

  test(
    'dogfood and ecology route payloads conform to checked-in schemas',
    () async {
      await File(p.join(tempDir.path, 'task.md')).writeAsString('- [ ] loop\n');

      final dogfood = await dogfoodStatusPayload(tempDir.path);
      final snapshot = await ecologySnapshotPayload(tempDir.path);
      final route = await ecologyRoutePayload(tempDir.path);

      expectSchemaConformance(
        dogfood,
        loadSchema('dogfood-status-v1.schema.json'),
      );
      expectSchemaConformance(
        snapshot,
        loadSchema('ecology-snapshot-v1.schema.json'),
      );
      expectSchemaConformance(
        route,
        loadSchema('ecology-route-v1.schema.json'),
      );
      expect(
        route['dispatch_lane_candidates'] as List,
        isNotEmpty,
        reason: 'candidate-bearing route output must be schema-covered',
      );

      final embeddedChecks =
          ((snapshot['schema_outputs'] as Map)['checks'] as List)
              .cast<Map<String, dynamic>>();
      expect(
        embeddedChecks.map((final check) => check['id']),
        isNot(contains('ecology-snapshot')),
        reason:
            'Ecology snapshot embeds core schema checks only; composite route checks are validated by schema check-outputs.',
      );
    },
  );
}

Map<String, dynamic> loadSchema(final String fileName) {
  final schemaFile = File(
    p.normalize(
      p.join(Directory.current.path, '..', '..', 'docs', 'schemas', fileName),
    ),
  );
  return jsonDecode(schemaFile.readAsStringSync()) as Map<String, dynamic>;
}

void expectSchemaConformance(
  final Map<String, dynamic> payload,
  final Map<String, dynamic> schema,
) => _expectValueConforms(payload, schema, r'$', schema);

void _expectObjectConformance(
  final Map<String, dynamic> payload,
  final Map<String, dynamic> schema,
  final String path,
  final Map<String, dynamic> rootSchema,
) {
  final required = ((schema['required'] as List?) ?? const <Object?>[])
      .cast<String>();
  final properties = Map<String, dynamic>.from(
    (schema['properties'] as Map?) ?? const {},
  );

  expect(payload.keys, containsAll(required));
  if (schema['additionalProperties'] == false) {
    for (final key in payload.keys) {
      expect(
        properties.containsKey(key),
        isTrue,
        reason: '$path.$key is not declared by schema',
      );
    }
  }

  for (final entry in properties.entries) {
    if (!payload.containsKey(entry.key)) continue;

    final property = Map<String, dynamic>.from(entry.value as Map);
    _expectValueConforms(
      payload[entry.key],
      property,
      '$path.${entry.key}',
      rootSchema,
    );
  }
}

void _expectValueConforms(
  final Object? value,
  final Map<String, dynamic> schema,
  final String path,
  final Map<String, dynamic> rootSchema,
) {
  final ref = schema[r'$ref'];
  if (ref is String) {
    _expectValueConforms(value, _resolveRef(ref, rootSchema), path, rootSchema);
    return;
  }

  if (schema.containsKey('const')) {
    expect(value, schema['const'], reason: path);
  }

  final enumValues = schema['enum'];
  if (enumValues is List) {
    expect(enumValues, contains(value), reason: path);
  }

  final type = schema['type'] as String?;
  if (type != null) {
    expect(
      _matchesSimpleType(value, type),
      isTrue,
      reason: '$path should be $type',
    );
  }

  if (type == 'array' && value is List) {
    final minItems = schema['minItems'];
    if (minItems is int) {
      expect(value.length, greaterThanOrEqualTo(minItems), reason: path);
    }
    final itemSchema = schema['items'];
    if (itemSchema is Map) {
      for (var index = 0; index < value.length; index++) {
        _expectValueConforms(
          value[index],
          Map<String, dynamic>.from(itemSchema),
          '$path[$index]',
          rootSchema,
        );
      }
    }
  }

  if (type == 'object' && value is Map) {
    _expectObjectConformance(
      Map<String, dynamic>.from(value),
      schema,
      path,
      rootSchema,
    );
  }

  final allOf = schema['allOf'];
  if (allOf is List) {
    for (var index = 0; index < allOf.length; index++) {
      final nested = allOf[index];
      if (nested is Map) {
        _expectValueConforms(
          value,
          Map<String, dynamic>.from(nested),
          '$path.allOf[$index]',
          rootSchema,
        );
      }
    }
  }

  final ifSchema = schema['if'];
  final thenSchema = schema['then'];
  if (ifSchema is Map && thenSchema is Map) {
    if (_matchesSchemaPredicate(value, Map<String, dynamic>.from(ifSchema))) {
      _expectValueConforms(
        value,
        Map<String, dynamic>.from(thenSchema),
        '$path.then',
        rootSchema,
      );
    }
  }
}

Map<String, dynamic> _resolveRef(
  final String ref,
  final Map<String, dynamic> rootSchema,
) {
  if (!ref.startsWith('#/')) {
    throw UnsupportedError(
      'Only local schema refs are supported in tests: $ref',
    );
  }
  Object? cursor = rootSchema;
  for (final segment in ref.substring(2).split('/')) {
    if (cursor is! Map) {
      throw StateError('Invalid schema ref: $ref');
    }
    cursor = cursor[segment];
  }
  if (cursor is! Map) {
    throw StateError('Schema ref does not point to an object: $ref');
  }
  return Map<String, dynamic>.from(cursor);
}

bool _matchesSchemaPredicate(
  final Object? value,
  final Map<String, dynamic> schema,
) {
  if (schema['properties'] case final Map properties when value is Map) {
    for (final entry in properties.entries) {
      final property = entry.value;
      if (property is! Map) continue;
      if (property.containsKey('const') &&
          value[entry.key] != property['const']) {
        return false;
      }
    }
  }
  return true;
}

bool _matchesSimpleType(final Object? value, final String type) =>
    switch (type) {
      'array' => value is List,
      'object' => value is Map,
      'string' => value is String,
      'boolean' => value is bool,
      'number' => value is num,
      'integer' => value is int,
      _ => true,
    };

Future<File> writeObservationFixture(final Directory root) async {
  final observationFile = File(
    p.join(root.path, '.steward', 'observations', 'obs-001.json'),
  )..createSync(recursive: true);
  await observationFile.writeAsString(
    '${jsonEncode({
      'schema': 'steward/observation/v1',
      'id': 'obs-001',
      'repo': 'sample_repo',
      'repo_commit': '0123456789abcdef0123456789abcdef01234567',
      'dirty': false,
      'created_at': '2026-06-12T00:00:00.000Z',
      'probe_id': 'quick',
      'action_id': 'doctor.local',
      'exit_code': 0,
      'summary': {'status': 'passed', 'stdout_excerpt': 'ok', 'stderr_excerpt': '', 'execution_count': 1, 'rejection_count': 0},
      'artifacts': const [],
      'redaction': {'policy': 'none'},
    })}\n',
  );
  return observationFile;
}

String validStewardV1() => '''
schema: steward/v1
repo:
  id: sample_repo
  archetype: cli_tool
harness:
  name: steward
  mode: cli
  entrypoints:
    cli: steward
adoption:
  status: adopting
  owner: sample_repo
  gate:
    pillar: quality

stewardship:
  governance:
    charter: AGENTS.md
  knowledge:
    docs_map: AGENTS.md
  repo_quality:
    contract_spec: steward.yaml
    maturity_model: general_stewardship
  skill_lifecycle:
    installable_skills: true
  quality:
    validate: steward validate
  harness:
    enabled: true
  release:
    changelog: CHANGELOG.md
  review_handoff:
    moe_required_for_architecture: true
  strategic_alignment:
    vision_source: AGENTS.md
  security:
    action_effects: required
  org:
    owners: AGENTS.md
actions:
  doctor.local:
    kind: command
    desc: Inspect Steward adoption state.
    command:
      argv: [steward, doctor, --json]
      shell: false
    cwd: .
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
    limits:
      timeout_ms: 10000
      max_output_bytes: 200000
    outputs:
      - id: stdout
        kind: stream
        required: true
        retention: summary
        format: json
    evidence:
      redact: []
probes:
  quick:
    profile: quick
    actions: [doctor.local]
diagnostics:
  cases: {}
unknown_cases:
  path: .steward/unknown-cases/
  retention: local
provenance:
  dependencies: []
  artifacts: []
  benchmarks: []
''';
