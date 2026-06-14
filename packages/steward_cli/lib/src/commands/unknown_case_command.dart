import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Groups append-only unknown-case evidence commands.
class UnknownCaseCommand extends Command<void> {
  UnknownCaseCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(UnknownCaseCreateCommand(outputSink, startDirectory));
  }

  @override
  final name = 'unknown-case';

  @override
  final description = 'Create append-only local unknown-case records.';
}

class UnknownCaseCreateCommand extends Command<void> {
  UnknownCaseCreateCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'from',
        mandatory: true,
        help: 'Path to a steward/observation/v1 JSON file.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'create';

  @override
  final description = 'Create an unknown-case record from an observation.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final fromPath = argResults?['from'] as String;
    final record = await createUnknownCasePayload(root, fromPath);

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(record));
      return;
    }

    sink
      ..writeln('Unknown case')
      ..writeln('- id: ${record['id']}')
      ..writeln('- path: ${record['path']}');
  }
}

Future<Map<String, dynamic>> createUnknownCasePayload(
  final String root,
  final String observationPath,
) async {
  final configResult = await StewardConfig.loadChecked(root);
  final config = configResult.config;
  final observation = await _readObservation(root, observationPath);
  final createdAt = DateTime.now().toUtc();
  final id = _recordId('unknown', createdAt);
  final basePath =
      config.unknownCases['path'] as String? ?? '.steward/unknown-cases';
  final allocation = _allocateRecordPath(root, basePath, id);
  final targetFile = File(allocation.path);

  final resolvedObservationPath = resolveUnderRoot(root, observationPath);
  final sourcePath = repoRelativePath(root, resolvedObservationPath);
  final observationRaw = await File(resolvedObservationPath).readAsString();
  final observationDigest = sha256
      .convert(utf8.encode(observationRaw))
      .toString();
  final summary = Map<String, dynamic>.from(
    observation['summary'] as Map? ?? const {},
  );
  final record = {
    'schema': 'steward/unknown-case/v1',
    'id': allocation.id,
    'status': 'unknown_case',
    'repo': observation['repo'] ?? config.repo['id'],
    'repo_commit': observation['repo_commit'],
    'dirty': observation['dirty'],
    'created_at': createdAt.toIso8601String(),
    'source_observation': {
      'id': observation['id'],
      'path': sourcePath,
      'schema': observation['schema'],
      'sha256': observationDigest,
    },
    'probe_id': observation['probe_id'],
    'action_id': observation['action_id'],
    'summary': {
      'status': summary['status'],
      'exit_code': observation['exit_code'],
      'stdout_excerpt': summary['stdout_excerpt'],
      'stderr_excerpt': summary['stderr_excerpt'],
      'execution_count': summary['execution_count'],
      'rejection_count': summary['rejection_count'],
    },
    'evidence': {
      'observation_path': sourcePath,
      'observation_sha256': observationDigest,
      'artifacts': observation['artifacts'] ?? const [],
      'redaction': observation['redaction'],
    },
    'review': {'status': 'pending', 'promoted': false},
    'retention': config.unknownCases['retention'] ?? 'local',
  };

  targetFile.parent.createSync(recursive: true);
  if (targetFile.existsSync()) {
    throw StateError('Unknown-case record already exists: ${allocation.id}');
  }
  await targetFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
    mode: FileMode.writeOnly,
  );

  return {...record, 'path': repoRelativePath(root, allocation.path)};
}

Future<Map<String, dynamic>> _readObservation(
  final String root,
  final String observationPath,
) async {
  final resolved = resolveUnderRoot(root, observationPath);
  final raw = await File(resolved).readAsString();
  final data = jsonDecode(raw);
  if (data is! Map || data['schema'] != 'steward/observation/v1') {
    throw const FormatException(
      'Input is not a steward/observation/v1 JSON file.',
    );
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
  throw StateError('Could not allocate a unique unknown-case id for $baseId.');
}

class _RecordAllocation {
  const _RecordAllocation(this.id, this.path);

  final String id;
  final String path;
}
