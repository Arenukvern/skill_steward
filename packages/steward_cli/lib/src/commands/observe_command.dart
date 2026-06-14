import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';
import 'probe_command.dart';

/// Captures a compact local observation record from a bounded probe.
class ObserveCommand extends Command<void> {
  ObserveCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'profile',
        defaultsTo: 'quick',
        allowed: const ['quick'],
        help: 'Probe profile to observe. Slice 1 supports quick only.',
      )
      ..addOption(
        'from',
        help: 'Create an observation from an existing probe JSON file.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'observe';

  @override
  final description = 'Write a compact local Steward observation record.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final profile = argResults?['profile'] as String? ?? 'quick';
    final fromPath = argResults?['from'] as String?;
    final result = await observePayload(root, profile, fromPath: fromPath);

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(result));
      return;
    }

    sink
      ..writeln('Steward observation')
      ..writeln('- id: ${result['id']}')
      ..writeln(
        '- status: ${(result['summary'] as Map<String, dynamic>)['status']}',
      )
      ..writeln('- path: ${result['path']}');
  }
}

Future<Map<String, dynamic>> observePayload(
  final String root,
  final String profile, {
  final String? fromPath,
}) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  final startedAt = DateTime.now().toUtc();
  final probe = fromPath == null
      ? await stewardProbePayload(root, configResult, profile)
      : await _readProbePayload(root, fromPath);
  final git = await _gitFacts(root);
  final allocation = _allocateRecordPath(
    root,
    p.join('.steward', 'observations'),
    _recordId('obs', startedAt),
  );
  final executions = (probe['executions'] as List? ?? const [])
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList();
  final failedExecution = _firstExecution(
    executions,
    where: (final execution) => execution['status'] != 'passed',
  );
  final firstExecution = _firstExecution(executions);
  final representative = failedExecution ?? firstExecution;
  final summary = {
    'status': probe['status'],
    'stdout_excerpt': _excerpt(representative?['stdout']),
    'stderr_excerpt': _excerpt(representative?['stderr']),
    'execution_count': executions.length,
    'rejection_count': (probe['rejections'] as List? ?? const []).length,
  };

  final observation = {
    'schema': 'steward/observation/v1',
    'id': allocation.id,
    'repo': config.repo['id'],
    'repo_commit': git.commit,
    'dirty': git.dirty,
    'profile': profile,
    'probe_id': probe['probe_id'],
    'action_id': representative?['action_id'],
    'started_at': startedAt.toIso8601String(),
    'duration_ms': _totalDurationMs(executions),
    'exit_code': representative?['exit_code'],
    'summary': summary,
    'probe': {
      'schema_version': probe['schema_version'],
      'status': probe['status'],
      'actions': probe['actions'],
      'rejections': probe['rejections'],
      'unknown_case': probe['unknown_case'],
    },
    'artifacts': <Map<String, dynamic>>[],
    'redaction': {
      'policy': 'steward/redaction/v1',
      'stdout_max_bytes': 4096,
      'stderr_max_bytes': 4096,
      'secrets_scanned': false,
    },
    'retention': config.unknownCases['retention'] ?? 'local',
  };

  final file = File(allocation.path)..parent.createSync(recursive: true);
  if (file.existsSync()) {
    throw StateError('Observation record already exists: ${allocation.id}');
  }
  final encoded =
      '${const JsonEncoder.withIndent('  ').convert(observation)}\n';
  await file.writeAsString(encoded);
  final digest = sha256.convert(utf8.encode(encoded)).toString();

  return {
    ...observation,
    'path': repoRelativePath(root, allocation.path),
    'sha256': digest,
  };
}

Future<Map<String, dynamic>> _readProbePayload(
  final String root,
  final String fromPath,
) async {
  final resolved = resolveUnderRoot(root, fromPath);
  final raw = await File(resolved).readAsString();
  final data = jsonDecode(raw);
  if (data is! Map || data['schema_version'] != 'steward.probe.v1') {
    throw const FormatException('Input is not a steward.probe.v1 JSON file.');
  }
  return Map<String, dynamic>.from(data);
}

String _recordId(final String prefix, final DateTime timestamp) {
  final compact = timestamp
      .toIso8601String()
      .replaceAll(RegExp('[^0-9A-Za-z]+'), '')
      .toLowerCase();
  return '$prefix-$compact';
}

_RecordAllocation _allocateRecordPath(
  final String root,
  final String relativeDir,
  final String baseId,
) {
  for (var index = 0; index < 1000; index++) {
    final id = index == 0
        ? baseId
        : '$baseId-${index.toString().padLeft(3, '0')}';
    final candidate = resolveUnderRoot(root, p.join(relativeDir, '$id.json'));
    if (!File(candidate).existsSync()) {
      return _RecordAllocation(id, candidate);
    }
  }
  throw StateError('Could not allocate a unique observation id for $baseId.');
}

String _excerpt(final Object? value) {
  final text = value?.toString() ?? '';
  if (text.length <= 4096) return text;
  return text.substring(0, 4096);
}

int _totalDurationMs(final List<Map<String, dynamic>> executions) {
  var total = 0;
  for (final execution in executions) {
    final duration = execution['duration_ms'];
    if (duration is int) {
      total += duration;
    }
  }
  return total;
}

Map<String, dynamic>? _firstExecution(
  final List<Map<String, dynamic>> executions, {
  final bool Function(Map<String, dynamic> execution)? where,
}) {
  for (final execution in executions) {
    if (where == null || where(execution)) {
      return execution;
    }
  }
  return null;
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
    return _GitFacts(
      commit: commitResult.exitCode == 0
          ? commitResult.stdout.toString().trim()
          : null,
      dirty:
          statusResult.exitCode == 0 &&
          statusResult.stdout.toString().trim().isNotEmpty,
    );
  } on Object catch (_) {
    return const _GitFacts(commit: null, dirty: null);
  }
}

class _GitFacts {
  const _GitFacts({required this.commit, required this.dirty});

  final String? commit;
  final bool? dirty;
}

class _RecordAllocation {
  const _RecordAllocation(this.id, this.path);

  final String id;
  final String path;
}
