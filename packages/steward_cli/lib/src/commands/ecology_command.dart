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

Future<Map<String, dynamic>> _schemaOutputsSnapshot(final String root) async {
  try {
    return await checkSchemaOutputsPayload(root);
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
        'Run benchmark with --output .steward/benchmark-summaries/<scenario>.json when a fresh result should feed future snapshots or blocked explain.',
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
            'Use steward benchmark --output to replace this persisted summary.',
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
