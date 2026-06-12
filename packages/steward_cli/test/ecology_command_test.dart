import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/ecology_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('steward_ecology_test_');
    File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsStringSync(jsonEncode({'skills': []}));
    File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsStringSync(validStewardV1());
    Directory(
      p.join(tempDir.path, 'docs', 'evidence'),
    ).createSync(recursive: true);
    File(
      p.join(tempDir.path, 'docs', 'evidence', 'current-dogfood-status.mdx'),
    ).writeAsStringSync('# Current dogfood status\n');
    Directory(
      p.join(tempDir.path, '.steward', 'benchmark-summaries'),
    ).createSync(recursive: true);
    File(
      p.join(
        tempDir.path,
        '.steward',
        'benchmark-summaries',
        'contract-smoke.json',
      ),
    ).writeAsStringSync(
      jsonEncode({
        'scenario': 'sample_repo.contract-smoke',
        'result': 'blocked',
        'blocked_by': 'durability_blocked',
        'run_id': '2026-06-12T00:00:00Z',
      }),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'ecology snapshot emits read-only inventory without status claims',
    () async {
      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(EcologyCommand(buffer, tempDir));

      await runner.run(['ecology', 'snapshot', '--json']);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['schema_version'], 'steward.ecology.snapshot.v1');
      expect(payload['status'], 'observed');
      expect(payload['config'], containsPair('schema', 'steward/v1'));
      expect(payload['actions'], containsPair('declared', 1));
      expect(
        (payload['actions'] as Map)['quick_eligible'] as List,
        contains('doctor.local'),
      );
      expect(
        (payload['evidence'] as Map)['current_dogfood_status_present'],
        isTrue,
      );
      expect(
        payload['benchmarks'],
        containsPair('summary_status', 'persisted_history'),
      );
      final summary =
          ((payload['benchmarks'] as Map)['persisted_summaries'] as List).single
              as Map;
      expect(summary['status'], 'persisted_history');
      expect(summary['blocked_by'], 'durability_blocked');
      expect(summary['may_be_stale'], isTrue);
      expect(summary, containsPair('fresh_result_route', isA<String>()));
      expect(
        payload['non_claims'],
        contains('This snapshot is inventory, not a maturity verdict.'),
      );
    },
  );
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
probes:
  quick:
    profile: quick
    actions: [doctor.local]
diagnostics:
  cases: {}
unknown_cases:
  path: .steward/unknown-cases/
provenance:
  benchmarks:
    - id: sample_repo.contract-smoke
      manifest: steward/scenarios/sample-contract-smoke.yaml
''';
