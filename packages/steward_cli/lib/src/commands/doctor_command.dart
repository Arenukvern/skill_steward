import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../output_guidance.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Prints a deterministic, read-only inventory of the local Steward contract.
class DoctorCommand extends Command<void> {
  DoctorCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addOption(
        'goal',
        help: 'Original task goal; preserved verbatim in advisory guidance.',
      )
      ..addFlag(
        'guidance',
        help: 'Include optional advice; default output contains facts only.',
      )
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.');
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'doctor';

  @override
  final description =
      'Maintainer. Do not start here. Inspect Steward adoption health. Not the native validation gate and not a preflight before ordinary edits.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await StewardConfig.loadChecked(root);
    final payload = stewardDoctorPayload(
      root,
      result,
      goal: argResults?['goal'] as String?,
      includeGuidance: argResults?['guidance'] == true,
    );

    final useJson = argResults?['json'] == true;
    if (argResults?['guidance'] == false) {
      payload.remove('guidance');
      payload['next_actions'] = <String>[];
    }
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
    if (argResults?['guidance'] != false) {
      writeOutputGuidance(sink, payload['guidance'] as Map<String, dynamic>);
    }
    for (final diagnostic in result.diagnostics) {
      sink.writeln(
        '- ${diagnostic.severity}: ${diagnostic.path}: ${diagnostic.message}',
      );
    }
  }
}

Map<String, dynamic> stewardDoctorPayload(
  final String root,
  final StewardConfigLoadResult result, {
  final String? goal,
  final bool includeGuidance = false,
}) {
  final config = result.config;
  final actions = config.typedActions;
  final nextActions = actions
      .where((final action) => action.isAutoEligible)
      .map((final action) => action.summaryJson())
      .toList();

  final payload = <String, dynamic>{
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
    'eligible_actions': nextActions,
    'next_actions': const [],
  };
  validateGuidanceGoal(goal);
  if (includeGuidance) {
    payload['guidance'] = outputGuidance(
      root,
      {'status': result.ok ? 'unknown' : 'blocked_invalid_config', ...payload},
      goal: goal,
      rerun: ['steward', 'doctor', '--json'],
    );
  }
  return payload;
}
