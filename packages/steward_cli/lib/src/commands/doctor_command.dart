import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Prints a deterministic, read-only inventory of the local Steward contract.
class DoctorCommand extends Command<void> {
  DoctorCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'doctor';

  @override
  final description =
      'Inspect Steward adoption state without running repository actions.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await StewardConfig.loadChecked(root);
    final payload = stewardDoctorPayload(root, result);

    final useJson = argResults?['json'] == true;
    final sink = outputSink ?? stdout;
    if (useJson) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    final config = payload['config'] as Map<String, dynamic>;
    sink
      ..writeln('Steward doctor')
      ..writeln('- root: $root')
      ..writeln('- schema: ${config['schema'] ?? 'legacy'}')
      ..writeln('- config valid: ${config['valid']}');
    for (final diagnostic in result.diagnostics) {
      sink.writeln(
        '- ${diagnostic.severity}: ${diagnostic.path}: ${diagnostic.message}',
      );
    }
  }
}

Map<String, dynamic> stewardDoctorPayload(
  final String root,
  final StewardConfigLoadResult result,
) {
  final config = result.config;
  final actions = config.typedActions;
  final nextActions = actions
      .where((final action) => action.isAutoEligible)
      .map((final action) => action.summaryJson())
      .toList();

  return {
    'schema_version': 'steward.doctor.v1',
    'root': root,
    'config': {
      'present': config.configPath != null,
      'path': config.configPath,
      'schema': config.schema,
      'valid': result.ok,
    },
    'repo': config.repo,
    'harness': config.harness,
    'stewardship_pillars': config.stewardship.keys.toList()..sort(),
    'diagnostics': result.diagnostics
        .map((final diagnostic) => diagnostic.toJson())
        .toList(),
    'actions': actions.map((final action) => action.summaryJson()).toList(),
    'probes': config.probes,
    'next_actions': nextActions,
  };
}
