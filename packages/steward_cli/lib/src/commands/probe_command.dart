import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../action_runner.dart';
import '../repo_root.dart';
import '../validation/steward_config.dart';

/// Runs a bounded Steward probe profile.
class ProbeCommand extends Command<void> {
  ProbeCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'profile',
        defaultsTo: 'quick',
        allowed: const ['quick'],
        help: 'Probe profile to run. Slice 1 supports quick only.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'probe';

  @override
  final description = 'Run a bounded Steward probe profile.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final profile = argResults?['profile'] as String? ?? 'quick';
    final result = await StewardConfig.loadChecked(root);
    final payload = await stewardProbePayload(root, result, profile);

    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    sink
      ..writeln('Steward probe')
      ..writeln('- profile: $profile')
      ..writeln('- status: ${payload['status']}');
    for (final rejected in payload['rejected_actions'] as List) {
      final item = rejected as Map<String, dynamic>;
      sink.writeln('- rejected ${item['id']}: ${item['reasons']}');
    }
    for (final execution in payload['executions'] as List) {
      final item = execution as Map<String, dynamic>;
      sink.writeln(
        '- ${item['action_id']}: ${item['status']} '
        '(exit ${item['exit_code']})',
      );
    }
  }
}

Future<Map<String, dynamic>> stewardProbePayload(
  final String root,
  final StewardConfigLoadResult result,
  final String profile,
) async {
  final config = result.config;
  final probeEntry = _findProbe(config, profile);
  final diagnostics = result.diagnostics
      .map((final diagnostic) => diagnostic.toJson())
      .toList();

  if (probeEntry == null) {
    return {
      'schema_version': 'steward.probe.v1',
      'root': root,
      'profile': profile,
      'probe_id': null,
      'config_valid': result.ok,
      'diagnostics': diagnostics,
      'status': 'missing_probe',
      'selected_actions': [],
      'rejected_actions': [
        {
          'id': null,
          'reasons': ['No probe declares profile "$profile".'],
        },
      ],
      'executions': [],
    };
  }

  final actionIds = _probeActionIds(probeEntry.value);
  final actionsById = {
    for (final action in config.typedActions) action.id: action,
  };
  final selected = <StewardAction>[];
  final rejected = <Map<String, dynamic>>[];
  final actionDecisions = <Map<String, dynamic>>[];

  for (final actionId in actionIds) {
    final action = actionsById[actionId];
    if (action == null) {
      final rejection = {
        'id': actionId,
        'action_id': actionId,
        'reason_code': 'unknown_action',
        'reasons': ['Action is not declared.'],
        'inspect_ref': 'steward action inspect $actionId --json',
      };
      rejected.add(rejection);
      actionDecisions.add({
        'id': actionId,
        'decision': 'rejected',
        'reason_code': rejection['reason_code'],
        'reasons': rejection['reasons'],
        'inspect_ref': rejection['inspect_ref'],
      });
      continue;
    }
    final violations = action.quickPolicyViolations();
    if (violations.isNotEmpty) {
      final rejection = {
        'id': actionId,
        'action_id': actionId,
        'reason_code': 'quick_policy_violation',
        'reasons': violations,
        'inspect_ref': 'steward action inspect $actionId --json',
      };
      rejected.add(rejection);
      actionDecisions.add({
        'id': actionId,
        'decision': 'rejected',
        'reason_code': rejection['reason_code'],
        'reasons': rejection['reasons'],
        'safety': action.safety,
        'effects': action.effects,
        'inspect_ref': rejection['inspect_ref'],
      });
      continue;
    }
    selected.add(action);
    actionDecisions.add({
      'id': actionId,
      'decision': result.ok ? 'selected' : 'skipped',
      'reason_code': result.ok ? null : 'invalid_config',
      'reasons': result.ok
          ? const <String>[]
          : const ['Config diagnostics must be resolved before execution.'],
      'safety': action.safety,
      'effects': action.effects,
      'inspect_ref': 'steward action inspect $actionId --json',
    });
  }

  final executions = <Map<String, dynamic>>[];
  if (result.ok) {
    for (final action in selected) {
      executions.add(await runStewardAction(root, action, quick: true));
    }
  }

  final status = _probeStatus(
    configValid: result.ok,
    actionIds: actionIds,
    rejected: rejected,
    executions: executions,
  );

  return {
    'schema_version': 'steward.probe.v1',
    'root': root,
    'profile': profile,
    'probe_id': probeEntry.key,
    'config_valid': result.ok,
    'policy': _quickPolicyJson(),
    'diagnostics': diagnostics,
    'status': status,
    'actions': actionDecisions,
    'selected_actions': selected
        .map((final action) => action.summaryJson())
        .toList(),
    'rejected_actions': rejected,
    'rejections': rejected,
    'observations': executions,
    'executions': executions,
    'unknown_case': {
      'recommended': status == 'failed' || status == 'blocked_invalid_config',
      'reason': status == 'failed'
          ? 'One or more quick probe actions failed.'
          : status == 'blocked_invalid_config'
          ? 'Config diagnostics must be resolved before probe evidence is useful.'
          : null,
      'path': config.unknownCases['path'],
    },
  };
}

Map<String, dynamic> _quickPolicyJson() => {
  'allowed_safety_classes': ['observe', 'bounded_local'],
  'requires_default_policy': 'auto',
  'max_timeout_ms': 10000,
  'denied_effects': ['network', 'secrets', 'destructive', 'repo_mutation'],
};

MapEntry<String, Map<String, dynamic>>? _findProbe(
  final StewardConfig config,
  final String profile,
) {
  for (final entry in config.probes.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final probe = Map<String, dynamic>.from(value);
    if (entry.key == profile || probe['profile'] == profile) {
      return MapEntry(entry.key, probe);
    }
  }
  return null;
}

List<String> _probeActionIds(final Map<String, dynamic> probe) {
  final actions = probe['actions'];
  if (actions is! List) return const [];
  return actions.whereType<String>().toList();
}

String _probeStatus({
  required final bool configValid,
  required final List<String> actionIds,
  required final List<Map<String, dynamic>> rejected,
  required final List<Map<String, dynamic>> executions,
}) {
  if (!configValid) return 'blocked_invalid_config';
  if (actionIds.isEmpty) return 'no_actions';
  if (rejected.isNotEmpty) return 'rejected';
  if (executions.any((final execution) => execution['status'] != 'passed')) {
    return 'failed';
  }
  return 'passed';
}
