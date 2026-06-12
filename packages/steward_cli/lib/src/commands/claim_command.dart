import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/claim_validator.dart';

class ClaimCommand extends Command<void> {
  ClaimCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(ClaimCheckCommand(outputSink, startDirectory));
  }

  @override
  final name = 'claim';

  @override
  final description = 'Run negative gates that reject stewardship overclaims.';
}

class ClaimCheckCommand extends Command<void> {
  ClaimCheckCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'claim',
        mandatory: true,
        help: 'Claim to test for overclaim risk, such as proven_repo_steward.',
      )
      ..addOption(
        'evidence',
        mandatory: true,
        help: 'Path to the evidence artifact for this claim.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'check';

  @override
  final description =
      'Reject claims that are stronger than their evidence artifact.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final claim = argResults?['claim'] as String;
    final evidencePath = argResults?['evidence'] as String;
    final payload = await checkClaimPayload(
      root,
      claim: claim,
      evidencePath: evidencePath,
    );
    final valid = payload['valid'] == true;
    final sink = outputSink ?? stdout;

    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
    } else {
      sink
        ..writeln('Steward claim negative gate')
        ..writeln('- claim: ${payload['claim']}')
        ..writeln('- result: ${payload['result']}')
        ..writeln('- accepted: ${payload['accepted']}');
      for (final diagnostic in payload['diagnostics'] as List) {
        sink.writeln('- diagnostic: $diagnostic');
      }
    }

    if (!valid) {
      exitCode = 1;
    }
  }
}

Future<Map<String, dynamic>> checkClaimPayload(
  final String root, {
  required final String claim,
  required final String evidencePath,
}) async {
  late final String resolved;
  try {
    resolved = resolveUnderRoot(root, evidencePath);
    // ignore: avoid_catching_errors, resolveUnderRoot reports unsafe paths this way.
  } on ArgumentError catch (error) {
    return ClaimCheckResult(
      claim: claim,
      valid: false,
      diagnostics: [error.message?.toString() ?? error.toString()],
      nonClaims: const [
        'Claim checks are negative gates; they do not accept or award steward status.',
      ],
    ).toJson();
  }

  final file = File(resolved);
  if (!file.existsSync()) {
    return ClaimCheckResult(
      claim: claim,
      valid: false,
      diagnostics: [
        'missing evidence file: ${repoRelativePath(root, resolved)}',
      ],
      nonClaims: const [
        'Claim checks are negative gates; they do not accept or award steward status.',
      ],
    ).toJson();
  }

  final result = const ClaimValidator().check(
    claim: claim,
    evidenceText: await file.readAsString(),
  );
  return result.toJson();
}
