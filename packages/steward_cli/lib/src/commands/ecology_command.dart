import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import '../validation/steward_config.dart';
import 'doctor_command.dart';
import 'schema_command.dart';

class EcologyCommand extends Command<void> {
  EcologyCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(EcologySnapshotCommand(outputSink, startDirectory));
    addSubcommand(EcologyRouteCommand(outputSink, startDirectory));
  }

  @override
  final name = 'ecology';

  @override
  final description = 'Inspect repo ecology inventory without awarding status.';
}

class EcologySnapshotCommand extends Command<void> {
  EcologySnapshotCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'snapshot';

  @override
  final description =
      'Emit a read-only repo ecology snapshot for stewardship review.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await ecologySnapshotPayload(root);
    final useJson = argResults?['json'] == true;
    final sink = outputSink ?? stdout;
    if (useJson) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    sink
      ..writeln('Steward ecology snapshot')
      ..writeln('- root: ${payload['root']}')
      ..writeln('- status: ${payload['status']}');
  }
}

class EcologyRouteCommand extends Command<void> {
  EcologyRouteCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'route';

  @override
  final description =
      'Route ecology facts into North Star dispositions without mutating.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await ecologyRoutePayload(root);
    final useJson = argResults?['json'] == true;
    final sink = outputSink ?? stdout;
    if (useJson) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    sink
      ..writeln('Steward ecology route')
      ..writeln('- root: ${payload['root']}')
      ..writeln('- status: ${payload['status']}');
    for (final disposition in payload['dispositions'] as List) {
      final item = disposition as Map<String, dynamic>;
      sink.writeln('- ${item['disposition']}: ${item['surface']}');
    }
  }
}

Future<Map<String, dynamic>> ecologySnapshotPayload(final String root) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  final doctor = stewardDoctorPayload(root, configResult);
  final schemaOutputs = await _schemaOutputsSnapshot(root);
  final git = await _gitSnapshot(root);
  final evidence = _evidenceSnapshot(root);
  final activePlans = _activePlanCandidates(root);
  final benchmarks = _benchmarkSnapshot(root, config, git);

  return {
    'schema_version': 'steward.ecology.snapshot.v1',
    'root': root,
    'status': 'observed',
    'config': doctor['config'],
    'repo': doctor['repo'],
    'stewardship_pillars': doctor['stewardship_pillars'],
    'actions': {
      'declared': config.typedActions.length,
      'quick_eligible': config.typedActions
          .where((final action) => action.isQuickEligible)
          .map((final action) => action.id)
          .toList(),
      'auto_eligible': config.typedActions
          .where((final action) => action.isAutoEligible)
          .map((final action) => action.id)
          .toList(),
    },
    'probes': {'declared': config.probes.keys.toList()..sort()},
    'benchmarks': benchmarks,
    'git': git,
    'schema_outputs': schemaOutputs,
    'active_plan_candidates': activePlans,
    'evidence': evidence,
    'diagnostics': configResult.diagnostics
        .map((final diagnostic) => diagnostic.toJson())
        .toList(),
    'non_claims': const [
      'This snapshot is inventory, not a maturity verdict.',
      'This snapshot does not prove H2, H4, H5, S5, adoption, or steward status.',
      'This snapshot does not execute repo actions or repair drift.',
      'Use repo-quality-system-lifecycle to interpret ecology dispositions.',
    ],
  };
}

Future<Map<String, dynamic>> ecologyRoutePayload(final String root) async {
  final snapshot = await ecologySnapshotPayload(root);
  final dispositions = _routeDispositions(snapshot);
  final laneCandidates = _dispatchLaneCandidates(dispositions);
  return {
    'schema_version': 'steward.ecology.route.v1',
    'root': root,
    'status': 'observed',
    'basis': 'steward.ecology.snapshot.v1',
    'value_paths': const [
      'orient',
      'compress',
      'validate',
      'tutor_pain',
      'promote_tool',
      'leave_native',
      'stop',
    ],
    'dispositions': dispositions,
    if (laneCandidates.isNotEmpty) 'dispatch_lane_candidates': laneCandidates,
    'non_claims': const [
      'This route is a stewardship disposition aid, not a maturity verdict.',
      'This route does not apply patches, execute repo actions, or repair drift.',
      'This route does not prove H2, H4, H5, S5, adoption, or steward status.',
      'Use native repo gates for product behavior before promoting Steward tooling.',
    ],
  };
}

List<Map<String, dynamic>> _dispatchLaneCandidates(
  final List<Map<String, dynamic>> dispositions,
) {
  final candidates = <Map<String, dynamic>>[];
  for (final disposition in dispositions) {
    final sourceDisposition = disposition['disposition'] as String? ?? '';
    if (sourceDisposition == 'leave_native' || sourceDisposition == 'stop') {
      continue;
    }

    final surface = disposition['surface'] as String? ?? 'repo ecology';
    final signal =
        disposition['signal'] as String? ?? 'Ecology signal observed.';
    final next =
        disposition['next'] as String? ?? 'Parent assigns the next step.';
    candidates.add({
      'lane_id':
          'lane-${candidates.length + 1}-${_slug(sourceDisposition)}-${_slug(surface)}',
      'source_disposition': sourceDisposition,
      'pain_signal': signal,
      'owner': surface,
      'scope': surface,
      'allowed_action': _allowedLaneAction(sourceDisposition),
      'write_set': const [],
      'forbidden_paths': const ['.steward/dispatch-lanes/**'],
      'owner_update_route': next,
      'dependencies': const [],
      'advisory_direct_fix_allowed': false,
      'risk_class': _laneRiskClass(sourceDisposition),
      'acceptance_check':
          'Parent assigns an exact lane, reviews the result, and records a terminal state.',
      'native_gate': _nativeGateForLane(sourceDisposition, surface),
      'suggested_claim_ceiling':
          'Advisory lane candidate observed from ecology route facts.',
      'non_claims': const [
        'Not write authorization.',
        'Not evidence that work was completed.',
        'Not a maturity, adoption, H2, H4, H5, S5, or steward-status claim.',
      ],
      'integration_rule':
          'Parent must assign, reject, or delete this candidate after synthesis.',
      'advisory': true,
      'ephemeral': true,
      'requires_parent_assignment': true,
      'not_write_authorization': true,
      'authorization_source': 'none',
      'retention': 'delete_after_integration',
    });
  }
  return candidates;
}

String _allowedLaneAction(final String disposition) => switch (disposition) {
  'compress' => 'compress',
  'validate' => 'verify',
  'tutor_pain' => 'explore',
  'promote_tool' => 'promote',
  _ => 'explore',
};

String _laneRiskClass(final String disposition) => switch (disposition) {
  'validate' || 'tutor_pain' => 'medium',
  _ => 'low',
};

String _nativeGateForLane(final String disposition, final String surface) {
  if (surface == 'schema outputs') {
    return 'steward schema check-outputs --json';
  }
  if (surface == 'steward.yaml') {
    return 'steward doctor --json';
  }
  if (surface == 'working tree') {
    return 'git status --short';
  }
  if (surface == '.steward/benchmark-summaries') {
    return 'rerun the exact benchmark scenario needed for the claim';
  }
  return switch (disposition) {
    'validate' => 'pnpm run validate',
    'compress' => 'pnpm run validate',
    _ => 'native repo gate or blocked state named by parent',
  };
}

String _slug(final String value) {
  final buffer = StringBuffer();
  var lastWasDash = false;
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final isAlphaNumeric =
        (rune >= 97 && rune <= 122) || (rune >= 48 && rune <= 57);
    if (isAlphaNumeric) {
      buffer.write(char);
      lastWasDash = false;
    } else if (!lastWasDash && buffer.isNotEmpty) {
      buffer.write('-');
      lastWasDash = true;
    }
  }
  final slug = buffer.toString();
  return slug.endsWith('-') ? slug.substring(0, slug.length - 1) : slug;
}

List<Map<String, dynamic>> _routeDispositions(
  final Map<String, dynamic> snapshot,
) {
  final dispositions = <Map<String, dynamic>>[];

  void add({
    required final String disposition,
    required final String surface,
    required final String signal,
    required final String next,
  }) {
    dispositions.add({
      'disposition': disposition,
      'surface': surface,
      'signal': signal,
      'next': next,
    });
  }

  final config = snapshot['config'] as Map? ?? const {};
  if (config['valid'] != true) {
    add(
      disposition: 'validate',
      surface: 'steward.yaml',
      signal: 'Steward config diagnostics are present.',
      next:
          'Address the owning config surface, then rerun the same Steward gate before making a claim.',
    );
  }

  final schemaOutputs = snapshot['schema_outputs'] as Map? ?? const {};
  if (schemaOutputs['valid'] != true) {
    add(
      disposition: 'validate',
      surface: 'schema outputs',
      signal: 'Machine-readable output checks are not valid.',
      next:
          'Align the output producer and schema before relying on JSON routes.',
    );
  }

  final activePlans = snapshot['active_plan_candidates'] as List? ?? const [];
  if (activePlans.isNotEmpty) {
    add(
      disposition: 'compress',
      surface: 'active plan candidates',
      signal: 'Plan-like files are present in the repo ecology.',
      next:
          'Extract durable truth into ADR, FAQ, code, skill, check, or current ledger, then remove stale plan scaffolding.',
    );
  }

  final evidence = snapshot['evidence'] as Map? ?? const {};
  final evidenceFiles = evidence['files'] as List? ?? const [];
  final templateOrPacketCount = evidenceFiles
      .where(
        (final file) =>
            '$file'.contains('template') ||
            '$file'.contains('packet') ||
            '$file'.contains('pdsa'),
      )
      .length;
  if (templateOrPacketCount > 0) {
    add(
      disposition: 'compress',
      surface: 'docs/evidence',
      signal: 'Evidence contains templates, packets, or PDSA history.',
      next:
          'Keep current ledgers visible; route templates and historical packets as archive or skill references.',
    );
  }

  final benchmarks = snapshot['benchmarks'] as Map? ?? const {};
  if (benchmarks['summaries_may_be_stale'] == true) {
    add(
      disposition: 'validate',
      surface: '.steward/benchmark-summaries',
      signal: 'Persisted benchmark summaries may be stale.',
      next:
          'Treat summaries as history unless rerun evidence is needed for an exact claim.',
    );
  }

  final git = snapshot['git'] as Map? ?? const {};
  if (git['dirty'] == true) {
    add(
      disposition: 'tutor_pain',
      surface: 'working tree',
      signal: 'The git working tree has local changes.',
      next:
          'Name whether the dirty paths are protected local state, contract inputs, or ordinary implementation residue.',
    );
  }

  final actions = snapshot['actions'] as Map? ?? const {};
  if (actions['declared'] == 0) {
    add(
      disposition: 'orient',
      surface: 'steward.yaml actions',
      signal: 'No typed Steward actions are declared.',
      next:
          'Use native repo gates first; add actions only when repeated friction proves a Steward surface is useful.',
    );
  }

  if (dispositions.isEmpty) {
    add(
      disposition: 'stop',
      surface: 'repo ecology',
      signal:
          'No immediate ecology disposition was inferred from the snapshot.',
      next:
          'Do not create new evidence, actions, or docs solely to keep looping.',
    );
  } else {
    add(
      disposition: 'leave_native',
      surface: 'product/domain work',
      signal: 'Steward routing is not the product runtime.',
      next:
          'Keep product behavior in native repo commands unless repeated friction earns a Steward surface.',
    );
  }

  return dispositions;
}

Future<Map<String, dynamic>> _schemaOutputsSnapshot(final String root) async {
  try {
    return await checkSchemaOutputsPayload(
      root,
      includeCompositeOutputs: false,
    );
  } on Object catch (error) {
    return {
      'schema_version': 'steward.schema.check_outputs.v1',
      'root': root,
      'valid': false,
      'status': 'not_checked',
      'checks': [],
      'diagnostics': ['$error'],
    };
  }
}

Future<Map<String, dynamic>> _gitSnapshot(final String root) async {
  final inside = await Process.run('git', [
    'rev-parse',
    '--is-inside-work-tree',
  ], workingDirectory: root);
  if (inside.exitCode != 0) {
    return {
      'available': false,
      'status': 'not_checked',
      'diagnostics': ['Not inside a git worktree.'],
    };
  }

  final head = await Process.run('git', [
    'rev-parse',
    'HEAD',
  ], workingDirectory: root);
  final status = await Process.run('git', [
    '--no-optional-locks',
    'status',
    '--short',
    '--untracked-files=normal',
  ], workingDirectory: root);
  final entries = status.stdout
      .toString()
      .split('\n')
      .where((final line) => line.trim().isNotEmpty)
      .toList();

  return {
    'available': true,
    'status': entries.isEmpty ? 'clean' : 'dirty',
    'commit': head.exitCode == 0 ? head.stdout.toString().trim() : null,
    'dirty': entries.isNotEmpty,
    'entries': entries,
  };
}

Map<String, dynamic> _benchmarkSnapshot(
  final String root,
  final StewardConfig config,
  final Map<String, dynamic> git,
) {
  final declared = <Map<String, dynamic>>[];
  final rawBenchmarks = config.provenance['benchmarks'];
  if (rawBenchmarks is List) {
    for (final item in rawBenchmarks) {
      if (item is Map) {
        declared.add(Map<String, dynamic>.from(item));
      }
    }
  }

  final summaries = <Map<String, dynamic>>[];
  final dir = Directory(p.join(root, '.steward', 'benchmark-summaries'));
  if (dir.existsSync()) {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((final file) => file.path.endsWith('.json'))
            .toList()
          ..sort((final a, final b) => a.path.compareTo(b.path));
    for (final file in files) {
      summaries.add(_benchmarkSummary(root, file, git));
    }
  }

  return {
    'declared': declared,
    'summary_status': 'persisted_history',
    'summaries_may_be_stale': true,
    'fresh_result_route':
        'Pipe fresh blocked JSON to steward blocked explain --stdin --json. Use --output only when a fresh result should replace persisted history or feed future snapshots.',
    'persisted_summaries': summaries,
    // Compatibility alias. Prefer persisted_summaries for new consumers.
    'latest_summaries': summaries,
  };
}

Map<String, dynamic> _benchmarkSummary(
  final String root,
  final File file,
  final Map<String, dynamic> git,
) {
  final relative = p.relative(file.path, from: root).replaceAll(r'\', '/');
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map) {
      final summaryCommit = decoded['repo_commit'];
      final headCommit = git['commit'];
      final headMatchesSummary = summaryCommit is String && headCommit is String
          ? summaryCommit == headCommit
          : null;
      return {
        'path': relative,
        'status': 'persisted_history',
        'scenario': decoded['scenario'],
        'result': decoded['result'],
        'blocked_by': decoded['blocked_by'],
        'run_id': decoded['run_id'],
        'repo_commit': summaryCommit,
        'head_commit': headCommit,
        'head_matches_summary': headMatchesSummary,
        'may_be_stale': headMatchesSummary != true || git['dirty'] == true,
        'fresh_result_route':
            'Rerun the benchmark for fresh truth; use --output only when this persisted summary should be replaced.',
      };
    }
  } on Object catch (error) {
    return {'path': relative, 'status': 'unreadable', 'diagnostic': '$error'};
  }
  return {
    'path': relative,
    'status': 'unreadable',
    'diagnostic': 'Benchmark summary is not a JSON object.',
  };
}

List<Map<String, dynamic>> _activePlanCandidates(final String root) {
  final candidates = <String>['task.md', 'implementation_plan.md'];

  final activeDir = Directory(p.join(root, 'docs', 'exec-plans', 'active'));
  if (activeDir.existsSync()) {
    final files = activeDir.listSync().whereType<File>().toList()
      ..sort((final a, final b) => a.path.compareTo(b.path));
    for (final file in files) {
      candidates.add(p.relative(file.path, from: root).replaceAll(r'\', '/'));
    }
  }

  return candidates
      .where((final relative) => File(p.join(root, relative)).existsSync())
      .map(
        (final relative) => {
          'path': relative,
          'status': 'observed',
          'route': 'extract_then_remove_or_explicitly_archive',
        },
      )
      .toList();
}

Map<String, dynamic> _evidenceSnapshot(final String root) {
  final evidenceDir = Directory(p.join(root, 'docs', 'evidence'));
  final files = <String>[];
  if (evidenceDir.existsSync()) {
    final entries =
        evidenceDir
            .listSync()
            .whereType<File>()
            .where((final file) => file.path.endsWith('.mdx'))
            .toList()
          ..sort((final a, final b) => a.path.compareTo(b.path));
    for (final file in entries) {
      files.add(p.relative(file.path, from: root).replaceAll(r'\', '/'));
    }
  }

  return {
    'files': files,
    'current_dogfood_status_present': File(
      p.join(root, 'docs', 'evidence', 'current-dogfood-status.mdx'),
    ).existsSync(),
  };
}
