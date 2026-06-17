import 'bounded_process.dart';
import 'path_safety.dart';
import 'validation/steward_config.dart';

/// Runs a declared Steward action using the action's own bounded limits.
Future<Map<String, dynamic>> runStewardAction(
  final String root,
  final StewardAction action, {
  final bool quick = false,
}) async {
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
  final timeoutMs = actionTimeoutMs(action, quick: quick);
  final outputLimit = actionOutputLimit(action);
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

List<String> actionRunPolicyViolations(final StewardAction action) {
  final violations = <String>[];
  if (action.kind != 'command') {
    violations.add('kind ${action.kind} is not runnable');
  }
  if (action.defaultPolicy != 'auto') {
    violations.add('safety.default_policy is not auto');
  }
  if (action.requiresConfirmation) {
    violations.add('safety.requires_confirmation is true');
  }
  if (action.safetyClass == 'repo_mutation' ||
      action.safetyClass == 'external' ||
      action.safetyClass == 'destructive') {
    violations.add('safety.class ${action.safetyClass} is not allowed');
  }
  if (action.command['shell'] == true) {
    violations.add('command.shell is true');
  }
  if (_truthyEffect(action.effects['network'])) {
    violations.add('effects.network is true');
  }
  if (_truthyEffect(action.effects['secrets'])) {
    violations.add('effects.secrets is true');
  }
  if (_truthyEffect(action.effects['destructive'])) {
    violations.add('effects.destructive is true');
  }
  if (_mutationEffect(action.effects['git'])) {
    violations.add('effects.git mutates repository state');
  }
  return violations;
}

Map<String, dynamic> actionRunPolicyJson() => {
  'allowed_kind': 'command',
  'requires_default_policy': 'auto',
  'denied_safety_classes': ['repo_mutation', 'external', 'destructive'],
  'denied_effects': ['network', 'secrets', 'destructive', 'repo_mutation'],
  'allows_declared_fs_write': true,
  'uses_declared_timeout_ms': true,
};

int actionTimeoutMs(final StewardAction action, {required final bool quick}) {
  final raw = action.limits['timeout_ms'];
  final declared = raw is int
      ? raw
      : quick
      ? 10000
      : 30000;
  if (declared < 1) return 1;
  if (quick && declared > 10000) return 10000;
  return declared;
}

int actionOutputLimit(final StewardAction action) {
  final raw = action.limits['max_output_bytes'];
  final declared = raw is int ? raw : 200000;
  if (declared < 1) return 1;
  return declared > 200000 ? 200000 : declared;
}

String? _resolveCwd(final String root, final String cwd) {
  try {
    return resolveUnderRoot(root, cwd);
  } on Object {
    return null;
  }
}

bool _truthyEffect(final Object? value) {
  if (value == true) return true;
  if (value is String) {
    return value == 'true' || value == 'write' || value == 'mutation';
  }
  return false;
}

bool _mutationEffect(final Object? value) {
  if (value == true) return true;
  if (value is String) {
    return value == 'write' ||
        value == 'mutation' ||
        value == 'destructive' ||
        value == 'push';
  }
  return false;
}

_CappedOutput _capOutput(final String output, final int limit) {
  if (output.length <= limit) {
    return _CappedOutput(output, truncated: false);
  }
  return _CappedOutput(output.substring(0, limit), truncated: true);
}

class _CappedOutput {
  const _CappedOutput(this.text, {required this.truncated});

  final String text;
  final bool truncated;
}
