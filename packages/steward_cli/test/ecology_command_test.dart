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

  test(
    'ecology snapshot reports dirty git state from nested command cwd',
    () async {
      _git(tempDir, 'init');
      _git(tempDir, 'config', 'user.email', 'steward@example.test');
      _git(tempDir, 'config', 'user.name', 'Skill Steward Test');
      _git(tempDir, 'add', '.');
      _git(tempDir, 'commit', '-m', 'baseline');

      File(
        p.join(tempDir.path, 'steward.yaml'),
      ).writeAsStringSync('${validStewardV1()}\n# local edit\n');
      File(p.join(tempDir.path, 'NOTES.md')).writeAsStringSync('scratch\n');
      final nested = Directory(p.join(tempDir.path, 'packages', 'steward_cli'))
        ..createSync(recursive: true);

      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(EcologyCommand(buffer, nested));

      await runner.run(['ecology', 'snapshot', '--json']);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      final git = payload['git'] as Map;

      expect(payload['root'], tempDir.path);
      expect(git['available'], isTrue);
      expect(git['status'], 'dirty');
      expect(git['dirty'], isTrue);
      expect(git['entries'], contains(startsWith(' M steward.yaml')));
      expect(git['entries'], contains('?? NOTES.md'));
    },
  );

  test(
    'ecology route emits North Star dispositions without awarding maturity',
    () async {
      File(p.join(tempDir.path, 'task.md')).writeAsStringSync('- [ ] loop\n');

      final buffer = StringBuffer();
      final runner = CommandRunner<void>('steward', 'test')
        ..addCommand(EcologyCommand(buffer, tempDir));

      await runner.run(['ecology', 'route', '--json']);

      final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
      expect(payload['schema_version'], 'steward.ecology.route.v1');
      expect(payload['status'], 'observed');
      expect(
        payload['value_paths'],
        containsAll([
          'orient',
          'compress',
          'validate',
          'tutor_pain',
          'promote_tool',
          'leave_native',
          'stop',
        ]),
      );

      final dispositions = (payload['dispositions'] as List)
          .cast<Map<String, dynamic>>();
      final laneCandidates = (payload['dispatch_lane_candidates'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        dispositions.map((final item) => item['disposition']),
        contains('compress'),
      );
      expect(
        dispositions.map((final item) => item['disposition']),
        contains('validate'),
      );
      expect(
        dispositions.map((final item) => item['disposition']),
        contains('leave_native'),
      );
      expect(
        laneCandidates.map((final item) => item['source_disposition']),
        contains('compress'),
      );
      expect(
        laneCandidates.map((final item) => item['source_disposition']),
        isNot(contains('leave_native')),
      );
      final compressCandidate = laneCandidates.firstWhere(
        (final item) => item['source_disposition'] == 'compress',
      );
      expect(compressCandidate, containsPair('advisory', true));
      expect(compressCandidate, containsPair('ephemeral', true));
      expect(
        compressCandidate,
        containsPair('requires_parent_assignment', true),
      );
      expect(compressCandidate, containsPair('not_write_authorization', true));
      expect(compressCandidate, containsPair('authorization_source', 'none'));
      expect(
        compressCandidate,
        containsPair('retention', 'delete_after_integration'),
      );
      expect(compressCandidate, containsPair('direct_fix_eligible', false));
      expect(compressCandidate, isNot(contains('direct_fix_allowed')));
      expect(jsonEncode(payload), isNot(contains('repair apply')));
      expect(
        payload['non_claims'],
        contains(
          'This route is a stewardship disposition aid, not a maturity verdict.',
        ),
      );
    },
  );
}

void _git(
  final Directory root,
  final String command, [
  final String? a,
  final String? b,
]) {
  final args = [command, ?a, ?b];
  final result = Process.runSync('git', args, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
  }
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
