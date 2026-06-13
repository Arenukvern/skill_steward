import 'dart:async';
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
    final Stream<List<int>>? inputStream,
  ]) {
    addSubcommand(
      BlockedExplainCommand(outputSink, startDirectory, inputStream),
    );
  }

  @override
  final name = 'blocked';

  @override
  final description = 'Explain blocked Steward JSON outputs as next actions.';
}

class BlockedExplainCommand extends Command<void> {
  BlockedExplainCommand([
    this.outputSink,
    this.startDirectory,
    this.inputStream,
  ]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addFlag(
        'stdin',
        negatable: false,
        help: 'Read blocked Steward JSON from stdin.',
      )
      ..addOption(
        'input',
        help:
            'Repository-relative JSON file from a blocked Steward command. Use "-" for stdin.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;
  final Stream<List<int>>? inputStream;

  @override
  final name = 'explain';

  @override
  final description = 'Convert a blocked result into next actions.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final inputPath = (argResults?['input'] as String?)?.trim();
    final fromStdin = argResults?['stdin'] == true || inputPath == '-';
    final hasConflictingSources =
        argResults?['stdin'] == true && inputPath != null && inputPath != '-';
    final payload = await explainBlockedPayload(
      root,
      inputPath: hasConflictingSources || fromStdin ? null : inputPath,
      inputJson: hasConflictingSources
          ? null
          : fromStdin
          ? await (inputStream ?? stdin).transform(utf8.decoder).join()
          : null,
      inputLabel: fromStdin ? 'stdin' : inputPath,
      sourceConflict: hasConflictingSources,
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
  final String? inputPath,
  final String? inputJson,
  final String? inputLabel,
  final bool sourceConflict = false,
}) async {
  if (sourceConflict) {
    return _payload(
      root: root,
      input: inputLabel ?? 'multiple inputs',
      decision: const BlockedRouteDecision(
        blockedBy: 'invalid_input',
        artifactRoute: 'fix_input_path',
        nextActions: ['Use either --input <path> or --stdin, not both.'],
      ),
    );
  }

  if (inputPath == null && inputJson == null) {
    return _payload(
      root: root,
      input: inputLabel ?? 'missing input',
      decision: const BlockedRouteDecision(
        blockedBy: 'invalid_input',
        artifactRoute: 'fix_input_path',
        nextActions: [
          'Pass --input <path>, use --input -, or pipe blocked JSON with --stdin.',
        ],
      ),
    );
  }

  if (inputPath != null && inputJson != null) {
    return _payload(
      root: root,
      input: inputLabel ?? inputPath,
      decision: const BlockedRouteDecision(
        blockedBy: 'invalid_input',
        artifactRoute: 'fix_input_path',
        nextActions: ['Use either file input or stdin input, not both.'],
      ),
    );
  }

  if (inputJson != null) {
    return _explainBlockedJson(
      root,
      inputLabel: inputLabel ?? 'stdin',
      inputJson: inputJson,
    );
  }

  late final String resolved;
  try {
    resolved = resolveUnderRoot(root, inputPath!);
  } on Object catch (error) {
    return _payload(
      root: root,
      input: inputPath!,
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

  return _explainBlockedJson(
    root,
    inputLabel: repoRelativePath(root, resolved),
    inputJson: await file.readAsString(),
  );
}

Map<String, dynamic> _explainBlockedJson(
  final String root, {
  required final String inputLabel,
  required final String inputJson,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(inputJson);
  } on FormatException catch (error) {
    return _payload(
      root: root,
      input: inputLabel,
      decision: BlockedRouteDecision(
        blockedBy: 'invalid_input',
        artifactRoute: 'fix_input_json',
        nextActions: ['Input JSON is invalid: ${error.message}.'],
      ),
    );
  }

  if (decoded is! Map) {
    return _payload(
      root: root,
      input: inputLabel,
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
  final decision = _routeBlockedPayload(
    blockedBy,
    blockingPaths,
    scenario: _scenarioId(input),
  );
  return _payload(root: root, input: inputLabel, decision: decision);
}

BlockedRouteDecision _routeBlockedPayload(
  final String blockedBy,
  final List<String> blockingPaths, {
  final String? scenario,
}) => switch (blockedBy) {
  'durability_blocked' => BlockedRouteDecision(
    blockedBy: blockedBy,
    artifactRoute: 'rerun_same_benchmark_after_tracking',
    nextActions: [
      if (blockingPaths.isEmpty)
        'Track or commit dirty benchmark contract inputs, then rerun the same strict benchmark.'
      else
        'Inspect blocking inputs: git status --short -- ${blockingPaths.join(' ')}.',
      _rerunBenchmarkAdvice(scenario),
      'Use --output only when this fresh result should replace persisted history.',
      'Claim H2 only from result: "pass"; keep blocked output as non-proof.',
    ],
  ),
  'strict_proof_blocked' => BlockedRouteDecision(
    blockedBy: blockedBy,
    artifactRoute: 'rerun_same_benchmark_after_strict_proof_repair',
    nextActions: [
      if (blockingPaths.isEmpty)
        'Inspect proof.blocking_paths and broad_read_actions, then narrow or track strict proof inputs.'
      else
        'Inspect strict proof inputs: git status --short -- ${blockingPaths.join(' ')}.',
      _rerunBenchmarkAdvice(scenario),
      'Use --output only when this fresh result should replace persisted history.',
      'Do not promote a strict proof block as executable proof.',
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
    final normalized = blockedBy.trim();
    if (normalized == 'invalid_config') {
      return 'blocked_invalid_config';
    }
    return normalized;
  }
  final status = input['status'];
  if (status == 'blocked_invalid_config') {
    return 'blocked_invalid_config';
  }
  final proof = input['proof'];
  if (proof is Map && proof['status'] == 'blocked') {
    return 'strict_proof_blocked';
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
  final paths = <String>[];
  void collect(final Object? section) {
    if (section is! Map || section['blocking_paths'] is! List) return;
    for (final path
        in (section['blocking_paths'] as List).whereType<String>()) {
      if (!paths.contains(path)) paths.add(path);
    }
  }

  final durability = input['durability'];
  final proof = input['proof'];
  collect(durability);
  collect(proof);
  return paths;
}

String? _scenarioId(final Map<String, dynamic> input) {
  final scenario = input['scenario'];
  if (scenario is String && scenario.trim().isNotEmpty) {
    return scenario.trim();
  }
  return null;
}

String _rerunBenchmarkAdvice(final String? scenario) {
  if (scenario == null) {
    return 'Rerun the identical benchmark with --strict --json, piping fresh output to steward blocked explain --stdin --json.';
  }
  return 'Rerun fresh JSON: steward benchmark --scenario $scenario --strict --json | steward blocked explain --stdin --json.';
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
