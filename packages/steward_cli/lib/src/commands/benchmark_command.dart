import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import '../bounded_process.dart';
import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

// ignore: do_not_use_environment
const _compiledStewardVersion = String.fromEnvironment('STEWARD_VERSION');

/// Runs compact runtime dogfood benchmark scenarios.
class BenchmarkCommand extends Command<void> {
  BenchmarkCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addFlag(
        'strict',
        negatable: false,
        help:
            'Block execution when broad-read actions could observe dirty files.',
      )
      ..addOption(
        'output',
        help:
            'Write the compact JSON benchmark summary to a repo-relative path.',
      )
      ..addOption(
        'scenario',
        mandatory: true,
        help: 'Scenario id from provenance.benchmarks.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'benchmark';

  @override
  final description = 'Run compact runtime dogfood benchmark scenarios.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await benchmarkPayload(
      root,
      argResults?['scenario'] as String,
      strict: argResults?['strict'] == true,
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(result);
    final outputPath = argResults?['output'] as String?;
    if (outputPath != null && outputPath.trim().isNotEmpty) {
      final outputFile = File(resolveUnderRoot(root, outputPath));
      outputFile.parent.createSync(recursive: true);
      outputFile.writeAsStringSync('$encoded\n');
    }

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(encoded);
      return;
    }

    sink
      ..writeln('Steward benchmark')
      ..writeln('- scenario: ${result['scenario']}')
      ..writeln('- result: ${result['result']}');
  }
}

Future<Map<String, dynamic>> benchmarkPayload(
  final String root,
  final String scenarioId, {
  final bool strict = false,
}) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  final diagnostics = <Map<String, dynamic>>[
    ...configResult.diagnostics.map(
      (final diagnostic) => {
        'severity': diagnostic.severity,
        'path': diagnostic.path,
        'message': diagnostic.message,
      },
    ),
  ];
  final scenario = await _findScenario(root, config, scenarioId, diagnostics);
  if (scenario == null) {
    throw UsageException('Unknown benchmark scenario "$scenarioId".', '');
  }

  final git = await _gitFacts(root);
  final runId = DateTime.now().toUtc().toIso8601String();
  final inputDigests = await _inputDigests(root, scenario);
  final durability = await _durability(
    root: root,
    scenario: scenario,
    git: git,
    inputDigests: inputDigests,
    diagnostics: diagnostics,
  );
  final safeFirstProbe = _safeFirstProbeDecision(config, scenario);
  final consideredActions = _requiredActions(scenario);
  final rejectedActions = <Map<String, dynamic>>[];
  final selectedActions = <StewardAction>[];

  if (safeFirstProbe['status'] != 'accepted') {
    rejectedActions.add({
      'id': scenario.safeFirstProbe,
      'reason_code': 'invalid_safe_first_probe',
      'reasons': safeFirstProbe['reasons'],
      'inspect_ref': 'steward action inspect ${scenario.safeFirstProbe} --json',
    });
  }

  for (final actionId in consideredActions) {
    final raw = config.actions[actionId];
    if (raw is! Map) {
      rejectedActions.add({
        'id': actionId,
        'reason_code': 'missing_action',
        'inspect_ref': 'steward action inspect $actionId --json',
      });
      continue;
    }
    final action = StewardAction.fromMap(
      actionId,
      Map<String, dynamic>.from(raw),
    );
    final violations = action.quickPolicyViolations();
    if (violations.isNotEmpty) {
      rejectedActions.add({
        'id': actionId,
        'reason_code': 'unsafe_action',
        'reasons': violations,
        'inspect_ref': 'steward action inspect $actionId --json',
      });
      continue;
    }
    selectedActions.add(action);
  }

  final proof = _proofStatus(
    strict: strict,
    git: git,
    selectedActions: selectedActions,
    inputDigests: inputDigests,
    diagnostics: diagnostics,
  );

  final status = scenario.status;
  final executions = <Map<String, dynamic>>[];
  if (configResult.ok &&
      status == 'runnable' &&
      durability.status != 'blocked' &&
      proof.status != 'blocked' &&
      rejectedActions.isEmpty) {
    for (final action in selectedActions) {
      executions.add(await _runAction(root, action));
    }
  }

  final artifacts = _artifactSummaries(root, scenario.artifacts, diagnostics);
  final result = _benchmarkResult(
    configValid: configResult.ok,
    status: status,
    durabilityStatus: durability.status,
    proofStatus: proof.status,
    rejectedActions: rejectedActions,
    executions: executions,
    artifacts: artifacts,
  );

  return {
    'schema': 'steward/benchmark-summary/v1',
    'repo': config.repo['id'] ?? scenario.repo,
    'repo_commit': git.commit,
    'dirty': git.dirty,
    'runner': await _runnerVersion(root),
    'scenario': scenario.id,
    'scenario_source': scenario.source,
    'scenario_manifest': scenario.manifestPath,
    'scenario_manifest_sha256': await _scenarioManifestSha256(root, scenario),
    'run_id': runId,
    'mode': 'cold_start',
    'result': result,
    'steps': executions.length,
    'actions_run': executions.map((final run) => run['action_id']).toList(),
    'selection_trace': {
      'safe_first_probe': safeFirstProbe,
      'considered_actions': consideredActions,
      'selected_actions': selectedActions
          .map((final action) => action.id)
          .toList(),
      'rejected_actions': rejectedActions,
    },
    'execution_summaries': executions.map(_executionSummary).toList(),
    'artifacts': artifacts,
    'input_digests': inputDigests,
    'durability': durability.toJson(),
    'proof': proof.toJson(),
    'owner': scenario.owner,
    'blocked_by': result == 'blocked'
        ? scenario.blockedBy ??
              _blockedReason(
                configResult.ok,
                status,
                durability.status,
                proof.status,
                rejectedActions,
              )
        : null,
    'lesson_status': 'none',
    'diagnostics': diagnostics,
  };
}

Future<_ScenarioManifest?> _findScenario(
  final String root,
  final StewardConfig config,
  final String scenarioId,
  final List<Map<String, dynamic>> diagnostics,
) async {
  final benchmarks = config.provenance['benchmarks'];
  if (benchmarks is! List) {
    diagnostics.add({
      'severity': 'error',
      'path': 'provenance.benchmarks',
      'message': 'provenance.benchmarks must be a list.',
    });
    return null;
  }
  for (var index = 0; index < benchmarks.length; index++) {
    final entry = benchmarks[index];
    if (entry is! Map) {
      diagnostics.add({
        'severity': 'error',
        'path': 'provenance.benchmarks.$index',
        'message': 'Benchmark scenario must be a map.',
      });
      continue;
    }
    final indexEntry = Map<String, dynamic>.from(entry);
    final manifestPath = indexEntry['manifest'] as String?;
    final manifestId =
        indexEntry['id'] as String? ?? indexEntry['scenario'] as String?;
    if (manifestPath != null && manifestPath.trim().isNotEmpty) {
      if (manifestId != null && manifestId != scenarioId) {
        continue;
      }
      final manifest = await _readScenarioManifest(
        root,
        manifestPath,
        'provenance.benchmarks.$index.manifest',
        diagnostics,
      );
      if (manifest == null) {
        continue;
      }
      final scenario = _ScenarioManifest(manifest, index, manifestPath);
      if (manifestId == scenarioId || scenario.id == scenarioId) {
        _validateScenario(scenario, diagnostics);
        return scenario;
      }
      continue;
    }
    final scenario = _ScenarioManifest(indexEntry, index, null);
    if (scenario.id == scenarioId) {
      _validateScenario(scenario, diagnostics);
      return scenario;
    }
  }
  return null;
}

Future<Map<String, dynamic>> _inputDigests(
  final String root,
  final _ScenarioManifest scenario,
) async {
  final digests = <String, dynamic>{};

  Future<void> addDigest(final String key, final String? path) async {
    if (path == null || path.trim().isEmpty) {
      return;
    }
    final normalized = path.replaceAll(r'\', '/');
    try {
      final file = File(resolveUnderRoot(root, normalized));
      if (!file.existsSync()) {
        digests[key] = {
          'path': repoRelativePath(root, file.path),
          'sha256': null,
        };
        return;
      }
      digests[key] = {
        'path': repoRelativePath(root, file.path),
        'sha256': sha256.convert(await file.readAsBytes()).toString(),
      };
    } on Object catch (error) {
      digests[key] = {'path': normalized, 'sha256': null, 'error': '$error'};
    }
  }

  await addDigest(
    'steward_contract',
    scenario.source['steward_contract'] as String?,
  );
  await addDigest('scenario_manifest', scenario.manifestPath);
  for (final artifact in scenario.artifacts) {
    if (artifact['durability'] == 'input') {
      await addDigest(
        'artifact:${artifact['id'] ?? ''}',
        artifact['path'] as String?,
      );
    }
  }
  return digests;
}

Future<_Durability> _durability({
  required final String root,
  required final _ScenarioManifest scenario,
  required final _GitFacts git,
  required final Map<String, dynamic> inputDigests,
  required final List<Map<String, dynamic>> diagnostics,
}) async {
  final source = scenario.source;
  final declaredCommit = source['commit'] as String?;
  final checkedPaths = <Map<String, dynamic>>[];
  final blockingPaths = <String>[];
  final warnings = <String>[];

  if (git.commit == null) {
    warnings.add('git HEAD is unavailable.');
  }

  if (declaredCommit == null ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(declaredCommit)) {
    warnings.add('source.commit is not a resolved 40-character git SHA.');
  } else if (git.commit != null && git.commit != declaredCommit) {
    warnings.add(
      'Local HEAD does not match source.commit; treating source.commit as the subject commit, not remote proof.',
    );
  }

  Future<void> addPath(final String kind, final String? path) async {
    if (path == null || path.trim().isEmpty) {
      return;
    }
    final normalized = path.replaceAll(r'\', '/');
    try {
      final resolved = resolveUnderRoot(root, normalized);
      final relPath = repoRelativePath(root, resolved);
      final status = await _gitPathStatus(root, relPath);
      checkedPaths.add({
        'kind': kind,
        'path': relPath,
        'git_status': status.code,
        'clean': status.clean,
        'sha256': (inputDigests[kind] as Map?)?['sha256'],
      });
      if (!status.clean) {
        blockingPaths.add(relPath);
      }
    } on Object catch (error) {
      checkedPaths.add({
        'kind': kind,
        'path': normalized,
        'git_status': 'invalid',
        'clean': false,
        'reason': '$error',
      });
      blockingPaths.add(normalized);
    }
  }

  await addPath('steward_contract', source['steward_contract'] as String?);
  await addPath('scenario_manifest', scenario.manifestPath);
  for (final artifact in scenario.artifacts) {
    if (artifact['durability'] == 'input') {
      await addPath(
        'artifact:${artifact['id'] ?? ''}',
        artifact['path'] as String?,
      );
    }
  }

  if (git.dirty == true) {
    warnings.add(
      'Repository has dirty files; unrelated dirty files do not block this benchmark.',
    );
  }

  if (git.commit == null && blockingPaths.isEmpty) {
    blockingPaths.add('<git HEAD>');
  }

  final status = blockingPaths.isEmpty ? 'ready' : 'blocked';
  if (warnings.isNotEmpty || blockingPaths.isNotEmpty) {
    diagnostics.add({
      'severity': 'warning',
      'path': 'durability',
      'message':
          'Benchmark durability status is $status; inspect durability.checked_paths and durability.warnings.',
    });
  }

  return _Durability(
    status: status,
    checkedPaths: checkedPaths,
    blockingPaths: blockingPaths,
    warnings: warnings,
  );
}

Future<String?> _scenarioManifestSha256(
  final String root,
  final _ScenarioManifest scenario,
) async {
  final manifestPath = scenario.manifestPath;
  if (manifestPath == null) {
    return null;
  }
  try {
    final file = File(resolveUnderRoot(root, manifestPath));
    if (!file.existsSync()) {
      return null;
    }
    return sha256.convert(await file.readAsBytes()).toString();
  } on Object {
    return null;
  }
}

Future<_GitPathStatus> _gitPathStatus(
  final String root,
  final String path,
) async {
  final result = await Process.run('git', [
    'status',
    '--porcelain',
    '--',
    path,
  ], workingDirectory: root);
  if (result.exitCode != 0) {
    return const _GitPathStatus(code: 'git_error', clean: false);
  }
  final output = result.stdout.toString().trim();
  if (output.isEmpty) {
    return const _GitPathStatus(code: 'clean', clean: true);
  }
  return _GitPathStatus(code: output.split(RegExp(r'\s+')).first, clean: false);
}

Future<Map<String, dynamic>?> _readScenarioManifest(
  final String root,
  final String manifestPath,
  final String diagnosticPath,
  final List<Map<String, dynamic>> diagnostics,
) async {
  try {
    final resolved = resolveUnderRoot(root, manifestPath);
    final data = _yamlToDart(loadYaml(await File(resolved).readAsString()));
    if (data is! Map) {
      diagnostics.add({
        'severity': 'error',
        'path': diagnosticPath,
        'message': 'Scenario manifest must contain a YAML mapping.',
      });
      return null;
    }
    return Map<String, dynamic>.from(data);
  } on Object catch (error) {
    diagnostics.add({
      'severity': 'error',
      'path': diagnosticPath,
      'message': '$error',
    });
    return null;
  }
}

void _validateScenario(
  final _ScenarioManifest scenario,
  final List<Map<String, dynamic>> diagnostics,
) {
  final prefix = 'provenance.benchmarks.${scenario.index}';
  if (scenario.schema != 'steward/scenario-manifest/v1') {
    diagnostics.add({
      'severity': 'error',
      'path': '$prefix.schema',
      'message': 'Scenario schema must be steward/scenario-manifest/v1.',
    });
  }
  for (final key in ['repo', 'scenario', 'status', 'safe_first_probe']) {
    if ('${scenario.raw[key] ?? ''}'.trim().isEmpty) {
      diagnostics.add({
        'severity': 'error',
        'path': '$prefix.$key',
        'message': '$key is required.',
      });
    }
  }
  if (!{'runnable', 'blocked', 'planned'}.contains(scenario.status)) {
    diagnostics.add({
      'severity': 'error',
      'path': '$prefix.status',
      'message': 'status must be runnable, blocked, or planned.',
    });
  }
  final source = scenario.raw['source'];
  if (source is! Map ||
      '${source['git'] ?? ''}'.trim().isEmpty ||
      '${source['commit'] ?? ''}'.trim().isEmpty ||
      '${source['steward_contract'] ?? ''}'.trim().isEmpty) {
    diagnostics.add({
      'severity': 'error',
      'path': '$prefix.source',
      'message':
          'source.git, source.commit, and source.steward_contract are required.',
    });
  }
  if (_requiredActions(scenario).isEmpty) {
    diagnostics.add({
      'severity': 'error',
      'path': '$prefix.required_actions',
      'message': 'required_actions must be a non-empty list.',
    });
  }
  if (scenario.raw['artifacts'] is! List) {
    diagnostics.add({
      'severity': 'error',
      'path': '$prefix.artifacts',
      'message': 'artifacts must be a list.',
    });
  }
  if (scenario.status == 'blocked' &&
      '${scenario.raw['blocked_by'] ?? ''}'.trim().isEmpty) {
    diagnostics.add({
      'severity': 'error',
      'path': '$prefix.blocked_by',
      'message': 'blocked scenarios must declare blocked_by.',
    });
  }
}

Map<String, dynamic> _safeFirstProbeDecision(
  final StewardConfig config,
  final _ScenarioManifest scenario,
) {
  final actionId = scenario.safeFirstProbe;
  final raw = config.actions[actionId];
  if (raw is! Map) {
    return {
      'id': actionId,
      'status': 'rejected',
      'reason_code': 'missing_action',
      'reasons': ['safe_first_probe is not declared in actions.'],
      'inspect_ref': 'steward action inspect $actionId --json',
    };
  }
  final action = StewardAction.fromMap(
    actionId,
    Map<String, dynamic>.from(raw),
  );
  final violations = action.quickPolicyViolations();
  if (violations.isNotEmpty) {
    return {
      'id': actionId,
      'status': 'rejected',
      'reason_code': 'unsafe_action',
      'reasons': violations,
      'inspect_ref': 'steward action inspect $actionId --json',
    };
  }
  return {
    'id': actionId,
    'status': 'accepted',
    'reason_code': null,
    'reasons': const <String>[],
    'inspect_ref': 'steward action inspect $actionId --json',
  };
}

List<String> _requiredActions(final _ScenarioManifest scenario) {
  final actions = scenario.raw['required_actions'];
  if (actions is! List) return const [];
  return actions.whereType<String>().toList();
}

List<Map<String, dynamic>> _artifactSummaries(
  final String root,
  final List<Map<String, dynamic>> artifacts,
  final List<Map<String, dynamic>> diagnostics,
) {
  final summaries = <Map<String, dynamic>>[];
  for (final artifact in artifacts) {
    final id = '${artifact['id'] ?? ''}';
    final path = artifact['path'] as String?;
    final required = artifact['required'] == true;
    if (path == null || path.trim().isEmpty) {
      summaries.add({...artifact, 'present': false, 'sha256': null});
      continue;
    }
    try {
      final resolved = resolveUnderRoot(root, path);
      final file = File(resolved);
      final present = file.existsSync();
      summaries.add({
        ...artifact,
        'present': present,
        'path': repoRelativePath(root, resolved),
        'sha256': present
            ? sha256.convert(file.readAsBytesSync()).toString()
            : null,
      });
      if (required && !present) {
        diagnostics.add({
          'severity': 'error',
          'path': 'artifacts.$id',
          'message': 'Required artifact is missing: $path',
        });
      }
    } on Object catch (error) {
      summaries.add({...artifact, 'present': false, 'sha256': null});
      diagnostics.add({
        'severity': 'error',
        'path': 'artifacts.$id',
        'message': '$error',
      });
    }
  }
  return summaries;
}

String _benchmarkResult({
  required final bool configValid,
  required final String status,
  required final String durabilityStatus,
  required final String proofStatus,
  required final List<Map<String, dynamic>> rejectedActions,
  required final List<Map<String, dynamic>> executions,
  required final List<Map<String, dynamic>> artifacts,
}) {
  if (!configValid || status == 'blocked' || status == 'planned') {
    return 'blocked';
  }
  if (durabilityStatus == 'blocked') return 'blocked';
  if (proofStatus == 'blocked') return 'blocked';
  if (rejectedActions.isNotEmpty) return 'blocked';
  if (executions.isEmpty) return 'blocked';
  if (executions.any((final run) => run['status'] != 'passed')) return 'fail';
  if (artifacts.any(
    (final artifact) =>
        artifact['required'] == true && artifact['present'] != true,
  )) {
    return 'fail';
  }
  return 'pass';
}

_ProofStatus _proofStatus({
  required final bool strict,
  required final _GitFacts git,
  required final List<StewardAction> selectedActions,
  required final Map<String, dynamic> inputDigests,
  required final List<Map<String, dynamic>> diagnostics,
}) {
  final warnings = <String>[];
  final blockingPaths = <String>[];
  final broadReadActions = selectedActions
      .where(_hasBroadFsRead)
      .map((final action) => action.id)
      .toList();
  final checkedInputPaths = inputDigests.values
      .whereType<Map>()
      .map((final input) => input['path'])
      .whereType<String>()
      .toSet();

  if (strict && broadReadActions.isNotEmpty && git.dirtyPaths.isNotEmpty) {
    final undeclaredDirtyPaths = git.dirtyPaths
        .where((final path) => !checkedInputPaths.contains(path))
        .toList();
    if (undeclaredDirtyPaths.isNotEmpty) {
      blockingPaths.addAll(undeclaredDirtyPaths);
      warnings.add(
        'Strict proof blocks broad fs_read actions from observing undeclared dirty files.',
      );
    }
  }

  final status = blockingPaths.isEmpty ? 'ready' : 'blocked';
  if (blockingPaths.isNotEmpty) {
    diagnostics.add({
      'severity': 'warning',
      'path': 'proof',
      'message':
          'Benchmark proof status is blocked; inspect proof.blocking_paths and proof.broad_read_actions.',
    });
  }

  return _ProofStatus(
    mode: strict ? 'strict' : 'standard',
    status: status,
    broadReadActions: broadReadActions,
    blockingPaths: blockingPaths,
    warnings: warnings,
  );
}

bool _hasBroadFsRead(final StewardAction action) {
  final fsRead = action.effects['fs_read'];
  if (fsRead is! List) return false;
  return fsRead.any((final entry) {
    final value = '$entry'.trim();
    return value == '.' || value == './' || value == '*' || value == '**';
  });
}

String _blockedReason(
  final bool configValid,
  final String status,
  final String durabilityStatus,
  final String proofStatus,
  final List<Map<String, dynamic>> rejectedActions,
) {
  if (!configValid) return 'invalid_config';
  if (status == 'planned') return 'scenario_planned';
  if (status == 'blocked') return 'scenario_blocked';
  if (durabilityStatus == 'blocked') return 'durability_blocked';
  if (proofStatus == 'blocked') return 'strict_proof_blocked';
  if (rejectedActions.isNotEmpty) return 'rejected_actions';
  return 'no_executions';
}

Future<Map<String, dynamic>> _runAction(
  final String root,
  final StewardAction action,
) async {
  final argv = action.command['argv'] as List? ?? const [];
  final cwd = action.raw['cwd'] as String? ?? '.';
  final workingDirectory = _resolveCwd(root, cwd);
  if (argv.isEmpty ||
      argv.any((final item) => item is! String) ||
      workingDirectory == null) {
    return {
      'action_id': action.id,
      'status': 'error',
      'exit_code': null,
      'duration_ms': 0,
      'stdout': '',
      'stderr': workingDirectory == null
          ? 'Action cwd resolves outside the repository root.'
          : 'Action command.argv is invalid.',
      'output_truncated': false,
    };
  }

  final args = argv.cast<String>();
  final timeoutMs = _timeoutMs(action);
  final outputLimit = _outputLimit(action);
  final started = DateTime.now();
  try {
    final process = await runBoundedProcess(
      args.first,
      args.skip(1).toList(),
      workingDirectory: workingDirectory,
      timeout: Duration(milliseconds: timeoutMs),
    );
    final durationMs = DateTime.now().difference(started).inMilliseconds;
    final stdoutText = '${process.stdout}';
    final stderrText = '${process.stderr}';
    final cappedStdout = _capOutput(stdoutText, outputLimit);
    final cappedStderr = _capOutput(stderrText, outputLimit);
    return {
      'action_id': action.id,
      'status': process.exitCode == 0 ? 'passed' : 'failed',
      'exit_code': process.exitCode,
      'duration_ms': durationMs,
      'stdout': cappedStdout.text,
      'stderr': cappedStderr.text,
      'output_truncated': cappedStdout.truncated || cappedStderr.truncated,
    };
  } on Object catch (error) {
    final durationMs = DateTime.now().difference(started).inMilliseconds;
    return {
      'action_id': action.id,
      'status': 'error',
      'exit_code': null,
      'duration_ms': durationMs,
      'stdout': '',
      'stderr': '$error',
      'output_truncated': false,
    };
  }
}

Map<String, dynamic> _executionSummary(final Map<String, dynamic> execution) {
  final stdout = execution['stdout']?.toString() ?? '';
  final stderr = execution['stderr']?.toString() ?? '';
  return {
    'action_id': execution['action_id'],
    'status': execution['status'],
    'exit_code': execution['exit_code'],
    'duration_ms': execution['duration_ms'],
    'stdout_sha256': sha256.convert(utf8.encode(stdout)).toString(),
    'stderr_sha256': sha256.convert(utf8.encode(stderr)).toString(),
    'output_truncated': execution['output_truncated'],
  };
}

String? _resolveCwd(final String root, final String cwd) {
  try {
    return resolveUnderRoot(root, cwd);
  } on Object {
    return null;
  }
}

int _timeoutMs(final StewardAction action) {
  final raw = action.limits['timeout_ms'];
  final declared = raw is int ? raw : 10000;
  if (declared < 1) return 1;
  return declared > 30000 ? 30000 : declared;
}

int _outputLimit(final StewardAction action) {
  final raw = action.limits['max_output_bytes'];
  final declared = raw is int ? raw : 200000;
  if (declared < 1) return 1;
  return declared > 200000 ? 200000 : declared;
}

_CappedOutput _capOutput(final String output, final int limit) {
  if (output.length <= limit) {
    return _CappedOutput(output, truncated: false);
  }
  return _CappedOutput(output.substring(0, limit), truncated: true);
}

Future<_GitFacts> _gitFacts(final String root) async {
  try {
    final commitResult = await Process.run('git', [
      'rev-parse',
      'HEAD',
    ], workingDirectory: root);
    final statusResult = await Process.run('git', [
      'status',
      '--porcelain',
    ], workingDirectory: root);
    final dirtyPaths = statusResult.exitCode == 0
        ? _dirtyPaths(statusResult.stdout.toString())
        : const <String>[];
    return _GitFacts(
      commit: commitResult.exitCode == 0
          ? commitResult.stdout.toString().trim()
          : null,
      dirty: dirtyPaths.isNotEmpty,
      dirtyPaths: dirtyPaths,
    );
  } on Object catch (_) {
    return const _GitFacts(commit: null, dirty: null, dirtyPaths: []);
  }
}

List<String> _dirtyPaths(final String porcelain) {
  final paths = <String>[];
  for (final line in porcelain.split('\n')) {
    if (line.trim().isEmpty) continue;
    final payload = line.length > 3 ? line.substring(3).trim() : line.trim();
    final path = payload.contains(' -> ')
        ? payload.split(' -> ').last.trim()
        : payload;
    if (path.isNotEmpty) paths.add(path);
  }
  return paths;
}

Future<String> _runnerVersion(final String root) async {
  if (_compiledStewardVersion.trim().isNotEmpty) {
    return 'steward@${_compiledStewardVersion.trim()}';
  }

  final scriptPath = Platform.script.isScheme('file')
      ? Platform.script.toFilePath()
      : '';
  final scriptPackagePubspec = scriptPath.isEmpty
      ? null
      : File('${File(scriptPath).parent.parent.path}/pubspec.yaml');
  final pubspec = scriptPackagePubspec?.existsSync() == true
      ? scriptPackagePubspec!
      : File('$root/packages/steward_cli/pubspec.yaml');
  if (!pubspec.existsSync()) {
    return 'steward@unknown';
  }
  try {
    final data = _yamlToDart(loadYaml(await pubspec.readAsString()));
    if (data is Map && '${data['version'] ?? ''}'.trim().isNotEmpty) {
      return 'steward@${data['version']}';
    }
  } on Object {
    // Keep benchmark summaries available even when package metadata is absent.
  }
  return 'steward@unknown';
}

Object? _yamlToDart(final Object? node) {
  if (node is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      node.entries.map(
        (final entry) =>
            MapEntry(entry.key.toString(), _yamlToDart(entry.value)),
      ),
    );
  }
  if (node is YamlList) {
    return node.map(_yamlToDart).toList();
  }
  return node;
}

class _ScenarioManifest {
  const _ScenarioManifest(this.raw, this.index, this.manifestPath);

  final Map<String, dynamic> raw;
  final int index;
  final String? manifestPath;

  String get schema => raw['schema'] as String? ?? '';
  String get repo => raw['repo'] as String? ?? '';
  String get id => raw['scenario'] as String? ?? '';
  String get status => raw['status'] as String? ?? '';
  String get safeFirstProbe => raw['safe_first_probe'] as String? ?? '';
  String get owner => raw['owner'] as String? ?? repo;
  String? get blockedBy => raw['blocked_by'] as String?;
  Map<String, dynamic> get source => raw['source'] is Map
      ? Map<String, dynamic>.from(raw['source'] as Map)
      : {};

  List<Map<String, dynamic>> get artifacts =>
      (raw['artifacts'] as List? ?? const [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
}

class _GitFacts {
  const _GitFacts({
    required this.commit,
    required this.dirty,
    required this.dirtyPaths,
  });

  final String? commit;
  final bool? dirty;
  final List<String> dirtyPaths;
}

class _ProofStatus {
  const _ProofStatus({
    required this.mode,
    required this.status,
    required this.broadReadActions,
    required this.blockingPaths,
    required this.warnings,
  });

  final String mode;
  final String status;
  final List<String> broadReadActions;
  final List<String> blockingPaths;
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'status': status,
    'broad_read_actions': broadReadActions,
    'blocking_paths': blockingPaths,
    'warnings': warnings,
  };
}

class _Durability {
  const _Durability({
    required this.status,
    required this.checkedPaths,
    required this.blockingPaths,
    required this.warnings,
  });

  final String status;
  final List<Map<String, dynamic>> checkedPaths;
  final List<String> blockingPaths;
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
    'status': status,
    'checked_paths': checkedPaths,
    'blocking_paths': blockingPaths,
    'warnings': warnings,
  };
}

class _GitPathStatus {
  const _GitPathStatus({required this.code, required this.clean});

  final String code;
  final bool clean;
}

class _CappedOutput {
  const _CappedOutput(this.text, {required this.truncated});

  final String text;
  final bool truncated;
}
