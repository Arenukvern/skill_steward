import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:steward_cli/src/commands/dogfood_command.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('steward_dogfood_test_');
    File(
      p.join(tempDir.path, 'skills.json'),
    ).writeAsStringSync(jsonEncode({'skills': []}));
    File(
      p.join(tempDir.path, 'steward.yaml'),
    ).writeAsStringSync(_validStewardV1());
    Directory(
      p.join(tempDir.path, 'docs', 'evidence'),
    ).createSync(recursive: true);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('dogfood status composes current ledger and ecology routing', () async {
    File(
      p.join(tempDir.path, 'docs', 'evidence', 'current-dogfood-status.mdx'),
    ).writeAsStringSync('''
---
status: current
evidence_type: ledger
date: 2026-06-13
claim_tested: Current narrow dogfood status.
proof_level: current ledger with local proof route
result: stewardship_protocol only
limitations: No maturity claim.
non_claims:
  - H5
  - proven_repo_steward
---

# Current dogfood status
''');
    Directory(
      p.join(tempDir.path, '.steward', 'benchmark-summaries'),
    ).createSync(recursive: true);
    File(
      p.join(tempDir.path, '.steward', 'benchmark-summaries', 'smoke.json'),
    ).writeAsStringSync(
      jsonEncode({
        'scenario': 'sample_repo.contract-smoke',
        'result': 'pass',
        'run_id': '2026-06-12T00:00:00Z',
      }),
    );

    final buffer = StringBuffer();
    final runner = CommandRunner<void>('steward', 'test')
      ..addCommand(DogfoodCommand(buffer, tempDir));

    await runner.run(['dogfood', 'status', '--json']);

    final payload = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    expect(payload['schema_version'], 'steward.dogfood.status.v1');
    expect((payload['current_ledger'] as Map)['present'], isTrue);
    expect(
      (payload['weakest_current_claim'] as Map)['result'],
      'stewardship_protocol only',
    );
    expect(
      (payload['ecology'] as Map)['persisted_summaries_may_be_stale'],
      isTrue,
    );
    expect(
      payload['next_actions'],
      contains(
        'Treat persisted benchmark summaries as history; rerun the exact benchmark for current proof.',
      ),
    );
    expect(
      payload['non_claims'],
      contains(
        'This command composes current routing facts; it does not award maturity.',
      ),
    );
  });

  test('dogfood status routes missing current ledger to minimal init', () async {
    final payload = await dogfoodStatusPayload(tempDir.path);

    expect((payload['current_ledger'] as Map)['present'], isFalse);
    expect(
      payload['next_actions'],
      contains(
        'Create a current ledger: steward evidence init --minimal or docs/evidence/current-dogfood-status.mdx.',
      ),
    );
  });

  test('dogfood status preserves nested ledger frontmatter', () async {
    File(
      p.join(tempDir.path, 'docs', 'evidence', 'current-dogfood-status.mdx'),
    ).writeAsStringSync('''
---
status: current
claim_tested: Current narrow dogfood status.
proof_level: current ledger
result: stewardship_protocol only
limitations:
  reason: local proof only
non_claims:
  - H5
  - proven_repo_steward
---

# Current dogfood status
''');

    final payload = await dogfoodStatusPayload(tempDir.path);
    final frontmatter =
        ((payload['current_ledger'] as Map)['frontmatter'] as Map)
            .cast<String, dynamic>();

    expect(frontmatter['limitations'], {'reason': 'local proof only'});
    expect(frontmatter['non_claims'], ['H5', 'proven_repo_steward']);
    expect((payload['weakest_current_claim'] as Map)['non_claims'], [
      'H5',
      'proven_repo_steward',
    ]);
  });
}

String _validStewardV1() => '''
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
actions: {}
probes: {}
diagnostics:
  cases: {}
unknown_cases:
  path: .steward/unknown-cases/
provenance:
  benchmarks: []
''';
