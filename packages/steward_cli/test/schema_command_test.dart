import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/dogfood_command.dart';
import 'package:steward_cli/src/commands/ecology_command.dart';
import 'package:steward_cli/src/commands/schema_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    exitCode = 0;
    tempDir = Directory.systemTemp.createTempSync('steward_schema_test_');
    File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsStringSync(jsonEncode({'skills': []}));
    File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsStringSync(validStewardV1());
  });

  tearDown(() {
    exitCode = 0;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('schema validate accepts a self-model artifact', () async {
    final file = File(p.join(tempDir.path, 'self-model.json'))
      ..writeAsStringSync(jsonEncode(validSelfModel()));
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SchemaCommand(buffer, tempDir));

    await runner.run([
      'schema',
      'validate',
      '--schema',
      'self-model',
      '--file',
      p.relative(file.path, from: tempDir.path),
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['schema_version'], 'steward.schema.validate.v1');
    expect(payload['schema'], 'self-model');
    expect(payload['valid'], isTrue);
    expect(payload['diagnostics'], isEmpty);
    expect(exitCode, 0);
  });

  test('schema validate rejects unknown self-model fields', () async {
    final invalid = validSelfModel()..['raw_memory'] = 'private chat excerpt';
    final file = File(p.join(tempDir.path, 'self-model.json'))
      ..writeAsStringSync(jsonEncode(invalid));
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SchemaCommand(buffer, tempDir));

    await runner.run([
      'schema',
      'validate',
      '--schema',
      'self-model',
      '--file',
      p.relative(file.path, from: tempDir.path),
      '--json',
    ]);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['valid'], isFalse);
    expect(
      payload['diagnostics'],
      contains(
        'self-model.json: ${r'$.raw_memory'} is not declared by schema.',
      ),
    );
    expect(exitCode, 1);
  });

  test(
    'schema validate accepts product experiment acceleration evidence',
    () async {
      final file = File(
        p.join(tempDir.path, 'experiment-campaign-summary.json'),
      )..writeAsStringSync(jsonEncode(validExperimentCampaignSummary()));
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(SchemaCommand(buffer, tempDir));

      await runner.run([
        'schema',
        'validate',
        '--schema',
        'experiment-campaign-summary',
        '--file',
        p.relative(file.path, from: tempDir.path),
        '--json',
      ]);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['schema_version'], 'steward.schema.validate.v1');
      expect(payload['schema'], 'experiment-campaign-summary');
      expect(payload['valid'], isTrue);
      expect(payload['diagnostics'], isEmpty);
      expect(exitCode, 0);
    },
  );

  test(
    'schema validate rejects product acceleration marked support only',
    () async {
      final invalid = validExperimentCampaignSummary()
        ..['support_only'] = true
        ..['screenshot_video_paths'] = const [];
      final file = File(
        p.join(tempDir.path, 'experiment-campaign-summary.json'),
      )..writeAsStringSync(jsonEncode(invalid));
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(SchemaCommand(buffer, tempDir));

      await runner.run([
        'schema',
        'validate',
        '--schema',
        'experiment-campaign-summary',
        '--file',
        p.relative(file.path, from: tempDir.path),
        '--json',
      ]);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['valid'], isFalse);
      expect(payload['diagnostics'] as List, isNotEmpty);
      expect(exitCode, 1);
    },
  );

  test('schema check-outputs validates current output shapes', () async {
    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(SchemaCommand(buffer, tempDir));

    await runner.run(['schema', 'check-outputs', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['schema_version'], 'steward.schema.check_outputs.v1');
    expect(payload['valid'], isTrue);
    final checks = (payload['checks'] as List).cast<Map<String, dynamic>>();
    final ids = checks.map((final check) => check['id']).toList();
    final schemas = checks.map((final check) => check['schema']).toList();
    expect(ids, containsAll(_publicOutputCheckIds));
    expect(schemas, containsAll(_publicOutputCheckIds));
    for (final id in _publicOutputCheckIds) {
      expect(ids.where((final value) => value == id), hasLength(1));
    }
    expect(checks, everyElement(containsPair('valid', true)));
    expect(exitCode, 0);
  });

  test(
    'ecology snapshot embeds core schema checks without recursion',
    () async {
      final payload = await ecologySnapshotPayload(tempDir.path);
      final checks = ((payload['schema_outputs'] as Map)['checks'] as List)
          .cast<Map<String, dynamic>>();
      final ids = checks.map((final check) => check['id']).toList();

      expect(ids, containsAll(['doctor', 'blocked-explain']));
      expect(ids, isNot(contains('dogfood-status')));
      expect(ids, isNot(contains('ecology-snapshot')));
      expect(ids, isNot(contains('ecology-route')));
    },
  );

  test('schema aliases validate dogfood and ecology JSON routes', () async {
    final cases = <String, Map<String, dynamic>>{
      'steward.dogfood.status.v1': await dogfoodStatusPayload(tempDir.path),
      'steward.ecology.snapshot.v1': await ecologySnapshotPayload(tempDir.path),
      'steward.ecology.route.v1': await ecologyRoutePayload(tempDir.path),
    };

    for (final entry in cases.entries) {
      final file = File(
        p.join(tempDir.path, '${entry.key.replaceAll('.', '-')}.json'),
      )..writeAsStringSync(jsonEncode(entry.value));
      final payload = await validateSchemaFilePayload(
        tempDir.path,
        schemaId: entry.key,
        filePath: p.relative(file.path, from: tempDir.path),
      );

      expect(payload['valid'], isTrue, reason: '${entry.key} diagnostics');
      expect(payload['diagnostics'], isEmpty);
    }
  });

  test(
    'ecology route schema rejects advisory candidates with write authorization',
    () async {
      final route = await ecologyRoutePayload(tempDir.path);
      route['dispatch_lane_candidates'] = [
        validDispatchLaneCandidate()..['direct_fix_allowed'] = true,
      ];
      final file = File(p.join(tempDir.path, 'ecology-route.json'))
        ..writeAsStringSync(jsonEncode(route));

      final payload = await validateSchemaFilePayload(
        tempDir.path,
        schemaId: 'steward.ecology.route.v1',
        filePath: p.relative(file.path, from: tempDir.path),
      );

      expect(payload['valid'], isFalse);
      expect(
        payload['diagnostics'],
        contains(
          'ecology-route.json: '
          r'$.dispatch_lane_candidates[0].direct_fix_allowed'
          ' is not declared by schema.',
        ),
      );
    },
  );

  test('schema emit accepts every public checked-in schema alias', () async {
    for (final alias in _publicCheckedInSchemaAliases) {
      final payload = await schemaEmitPayload(
        tempDir.path,
        schemaId: alias,
        source: 'checked-in',
      );

      expect(payload['valid'], isTrue, reason: '$alias diagnostics');
      expect(payload['diagnostics'], isEmpty);
      expect(
        (payload['json_schema'] as Map<String, dynamic>)[r'$id'],
        endsWith('/$alias.schema.json'),
      );
    }
  });

  test('schema validate accepts benchmark summary public schema id', () async {
    final file = File(p.join(tempDir.path, 'benchmark-summary.json'))
      ..writeAsStringSync(jsonEncode(validBenchmarkSummary()));

    final payload = await validateSchemaFilePayload(
      tempDir.path,
      schemaId: 'steward/benchmark-summary/v1',
      filePath: p.relative(file.path, from: tempDir.path),
    );

    expect(payload['schema'], 'benchmark-summary');
    expect(payload['valid'], isTrue);
    expect(payload['diagnostics'], isEmpty);
  });
}

const _publicOutputCheckIds = [
  'doctor',
  'blocked-explain',
  'dogfood-status',
  'ecology-snapshot',
  'ecology-route',
];

const _publicCheckedInSchemaAliases = [
  'action-candidate-v1',
  'adoption-run-v2',
  'benchmark-summary-v1',
  'blocked-explain-v1',
  'claim-check-v1',
  'doctor-v1',
  'dogfood-status-v1',
  'ecology-route-v1',
  'ecology-snapshot-v1',
  'experiment-campaign-summary-v1',
  'mode-event-v1',
  'observation-v1',
  'plugin-bundle-index-v1',
  'plugin-bundle-v1',
  'plugin-manifest-v1',
  'protocol-validate-v1',
  'scenario-manifest-v1',
  'schema-check-outputs-v1',
  'schema-drift-v1',
  'schema-emit-v1',
  'schema-validate-v1',
  'self-model-v1',
  'steward-v1',
  'unknown-case-v1',
];

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

Map<String, dynamic> validExperimentCampaignSummary() => {
  'schema': 'steward/experiment-campaign-summary/v1',
  'original_goal': 'Improve spark_physics_ecs splat rendering.',
  'product_repo': '/tmp/ecsly',
  'baseline_metrics': {'oracle_score': 0.4, 'confetti_artifact_score': 0.8},
  'variant_count': 2,
  'winning_variant': {
    'id': 'v001',
    'label': 'strict parity candidate',
    'controls': {'strict_enabled': true},
    'metrics': {
      'oracle_score': 0.7,
      'nonblank': true,
      'confetti_artifact_score': 0.2,
    },
    'screenshot_path': 'build/experiment-runs/run/screenshots/v001.png',
  },
  'before_after_metrics': {
    'before': {'oracle_score': 0.4, 'confetti_artifact_score': 0.8},
    'after': {'oracle_score': 0.7, 'confetti_artifact_score': 0.2},
    'deltas': {'oracle_score': 0.3, 'confetti_artifact_score': -0.6},
  },
  'screenshot_video_paths': [
    {
      'variant_id': 'v001',
      'screenshot_path': 'build/experiment-runs/run/screenshots/v001.png',
    },
  ],
  'product_surface_changed_or_directly_proven':
      'spark_physics_ecs runtime capture directly proved a product-owned visual improvement.',
  'non_claims': ['Not release readiness.'],
  'product_acceleration': true,
  'support_only': false,
};

Map<String, dynamic> validDispatchLaneCandidate() => {
  'lane_id': 'lane-001-compress-active-plan-candidates',
  'source_disposition': 'compress',
  'pain_signal': 'Plan-like files are present in the repo ecology.',
  'owner': 'active plan candidates',
  'scope': 'active plan candidates',
  'allowed_action': 'compress',
  'write_set': const [],
  'forbidden_paths': const [],
  'owner_update_route':
      'Extract durable truth into ADR, FAQ, code, skill, check, or current ledger.',
  'dependencies': const [],
  'advisory_direct_fix_allowed': false,
  'risk_class': 'low',
  'acceptance_check':
      'Parent assigns an exact lane or extracts durable truth elsewhere.',
  'native_gate': 'pnpm run validate',
  'suggested_claim_ceiling':
      'Advisory lane candidate observed from ecology route facts.',
  'non_claims': const [
    'Not write authorization.',
    'Not evidence that work was completed.',
  ],
  'integration_rule': 'Parent must assign, reject, or delete after synthesis.',
  'advisory': true,
  'ephemeral': true,
  'requires_parent_assignment': true,
  'not_write_authorization': true,
  'authorization_source': 'none',
  'retention': 'delete_after_integration',
};

Map<String, dynamic> validBenchmarkSummary() => {
  'schema': 'steward/benchmark-summary/v1',
  'repo': 'sample_repo',
  'repo_commit': '0123456789abcdef0123456789abcdef01234567',
  'dirty': false,
  'runner': 'steward',
  'scenario': 'sample.protocol-smoke',
  'scenario_source': {
    'git': 'https://github.com/example/sample_repo.git',
    'commit': '0123456789abcdef0123456789abcdef01234567',
  },
  'run_id': 'run-2026-06-13',
  'mode': 'strict',
  'result': 'pass',
  'actions_run': ['doctor.local'],
  'selection_trace': {'profile': 'quick'},
  'artifacts': <Map<String, dynamic>>[],
  'input_digests': <String, Map<String, dynamic>>{},
  'durability': {
    'status': 'ready',
    'checked_paths': [
      {
        'kind': 'contract',
        'path': 'steward.yaml',
        'git_status': 'clean',
        'clean': true,
      },
    ],
    'blocking_paths': <String>[],
    'warnings': <String>[],
  },
  'proof': {
    'mode': 'strict',
    'status': 'ready',
    'broad_read_actions': <String>[],
    'blocking_paths': <String>[],
    'warnings': <String>[],
  },
  'owner': 'sample_repo',
  'lesson_status': 'not_promoted',
};

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
