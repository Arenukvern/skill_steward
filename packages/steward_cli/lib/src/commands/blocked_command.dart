import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../contracts/blocked_contracts.dart';
import '../path_safety.dart';
import '../repo_root.dart';

class BlockedCommand extends Command<void> {
  BlockedCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(BlockedExplainCommand(outputSink, startDirectory));
  }

  @override
  final name = 'blocked';

  @override
  final description = 'Explain blocked Steward JSON outputs as next actions.';
}

class BlockedExplainCommand extends Command<void> {
  BlockedExplainCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'input',
        mandatory: true,
        help: 'Repository-relative JSON file from a blocked Steward command.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'explain';

  @override
  final description = 'Convert a blocked result into next actions.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await explainBlockedPayload(
      root,
      inputPath: argResults?['input'] as String,
    );
    final sink = outputSink ?? stdout;
    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
    } else {
      sink
        ..writeln('Steward blocked explanation')
        ..writeln('- blocked_by: ${payload['blocked_by']}')
        ..writeln('- artifact_route: ${payload['artifact_route']}');
      for (final action in payload['next_actions'] as List) {
        sink.writeln('- next: $action');
      }
    }
  }
}

Future<Map<String, dynamic>> explainBlockedPayload(
  final String root, {
  required final String inputPath,
}) async {
  late final String resolved;
  try {
    resolved = resolveUnderRoot(root, inputPath);
  } on Object catch (error) {
    return _payload(
      root: root,
      input: inputPath,
      decision: BlockedRouteDecision(
        blockedBy: 'invalid_input',
        artifactRoute: 'fix_input_path',
        nextActions: [
          if (error is ArgumentError) '${error.message}' else '$error',
        ],
      ),
    );
  }

  final file = File(resolved);
  if (!file.existsSync()) {
    return _payload(
      root: root,
      input: repoRelativePath(root, resolved),
      decision: const BlockedRouteDecision(
        blockedBy: 'missing_input',
        artifactRoute: 'fix_input_path',
        nextActions: ['Create or point --input at an existing JSON file.'],
      ),
    );
  }

  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map) {
    return _payload(
      root: root,
      input: repoRelativePath(root, resolved),
      decision: const BlockedRouteDecision(
        blockedBy: 'invalid_input',
        artifactRoute: 'fix_input_json',
        nextActions: ['Input JSON must be an object.'],
      ),
    );
  }

  final input = Map<String, dynamic>.from(decoded);
  final blockedBy = _detectBlockedBy(input);
  final blockingPaths = _blockingPaths(input);
  final decision = _routeBlockedPayload(blockedBy, blockingPaths);
  return _payload(
    root: root,
    input: repoRelativePath(root, resolved),
    decision: decision,
  );
}

BlockedRouteDecision _routeBlockedPayload(
  final String blockedBy,
  final List<String> blockingPaths,
) => switch (blockedBy) {
  'durability_blocked' => BlockedRouteDecision(
    blockedBy: blockedBy,
    artifactRoute: 'rerun_same_benchmark_after_tracking',
    nextActions: [
      if (blockingPaths.isEmpty)
        'Track or commit dirty benchmark contract inputs, then rerun the same strict benchmark.'
      else
        'Track or commit blocking inputs: ${blockingPaths.join(', ')}.',
      'Rerun the identical benchmark command before claiming H2 proof.',
      'Record result: "pass" only if durability becomes ready.',
    ],
  ),
  'blocked_invalid_config' => BlockedRouteDecision(
    blockedBy: blockedBy,
    artifactRoute: 'repair_config_or_unknown_case',
    nextActions: [
      'Repair steward.yaml schema diagnostics first.',
      'Rerun steward doctor --json and steward probe --profile quick --json.',
      'Create an unknown-case artifact if the schema cannot represent the repo honestly.',
    ],
  ),
  'runtime_proof_blocked' => BlockedRouteDecision(
    blockedBy: blockedBy,
    artifactRoute: 'unknown_case_runtime_block',
    nextActions: [
      'Capture the command, exit state, redacted log excerpt, and cleanup action.',
      'Name the exact runtime rerun target, such as VM URI or semantic node proof.',
      'Do not promote prior runtime evidence as fresh proof.',
    ],
  ),
  _ => BlockedRouteDecision(
    blockedBy: blockedBy,
    artifactRoute: 'inspect_blocked_payload',
    nextActions: [
      'Inspect the payload and choose config repair, unknown-case, or rerun route.',
    ],
  ),
};

String _detectBlockedBy(final Map<String, dynamic> input) {
  final blockedBy = input['blocked_by'];
  if (blockedBy is String && blockedBy.trim().isNotEmpty) {
    return blockedBy;
  }
  final status = input['status'];
  if (status == 'blocked_invalid_config') {
    return 'blocked_invalid_config';
  }
  final text = jsonEncode(input).toLowerCase();
  if (text.contains('vm service') ||
      text.contains('debug connection') ||
      text.contains('runtime proof')) {
    return 'runtime_proof_blocked';
  }
  return 'unknown_block';
}

List<String> _blockingPaths(final Map<String, dynamic> input) {
  final durability = input['durability'];
  if (durability is Map && durability['blocking_paths'] is List) {
    return (durability['blocking_paths'] as List).whereType<String>().toList();
  }
  return const [];
}

Map<String, dynamic> _payload({
  required final String root,
  required final String input,
  required final BlockedRouteDecision decision,
}) => BlockedExplanationPayload(
  root: root,
  input: input,
  blockedBy: decision.blockedBy,
  artifactRoute: decision.artifactRoute,
  nextActions: decision.nextActions,
  nonClaims: const [
    'This is blocked evidence, not proof.',
    'This explanation does not repair the repository or raise maturity status.',
  ],
).toJson();
