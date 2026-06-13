import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';

/// Groups lightweight evidence artifact commands.
class EvidenceCommand extends Command<void> {
  EvidenceCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(EvidenceInitCommand(outputSink, startDirectory));
  }

  @override
  final name = 'evidence';

  @override
  final description = 'Initialize minimal claim-proof evidence surfaces.';
}

class EvidenceInitCommand extends Command<void> {
  EvidenceInitCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag(
        'minimal',
        negatable: false,
        help: 'Create only docs/evidence/current-status.mdx.',
      )
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.');
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'init';

  @override
  final description = 'Create a minimal current evidence ledger.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final result = await initializeMinimalEvidence(root);
    final sink = outputSink ?? stdout;

    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(result));
      return;
    }

    sink
      ..writeln(
        result['created'] == true
            ? 'Created evidence ledger.'
            : 'Evidence ledger already exists.',
      )
      ..writeln('- path: ${result['path']}')
      ..writeln('- next: name the exact claim before adding proof');
  }
}

Future<Map<String, dynamic>> initializeMinimalEvidence(
  final String root,
) async {
  final evidenceDir = Directory(p.join(root, 'docs', 'evidence'))
    ..createSync(recursive: true);
  final file = File(p.join(evidenceDir.path, 'current-status.mdx'));
  final relativePath = p.relative(file.path, from: root);
  final created = !file.existsSync();

  if (created) {
    final date = DateTime.now().toIso8601String().split('T').first;
    await file.writeAsString(_currentStatusLedger(date, relativePath));
  }

  return {
    'schema_version': 'steward.evidence.init.v1',
    'path': relativePath,
    'created': created,
    'status': 'current',
    'evidence_type': 'ledger',
    'next_actions': [
      'Name the exact claim before adding proof.',
      'Use native validation or blocked evidence before readiness language.',
      'Move repeated deterministic drift to a check, schema, validator, test, CLI diagnostic, or probe.',
    ],
  };
}

String _currentStatusLedger(final String date, final String currentPath) =>
    '''
---
status: current
evidence_type: ledger
date: $date
scope: repository claim and proof status
claim_tested: Current weakest true repository claims.
proof_level: current ledger initialized; fill with native validation, blocked evidence, or linked proof artifacts
commands_or_sources:
  - native validation command
result: baseline ledger initialized; no readiness or maturity claim yet
limitations: Populate after validation, benchmark, or blocked evidence exists.
non_claims:
  - maturity
  - harness readiness
  - product runtime correctness
next_disposition: keep as current status pointer until superseded
current_status_pointer: $currentPath
---

# Current Evidence Status

Use this ledger for the weakest true current claim. Historical evidence is provenance unless this file points to it.

## Current Claims

| Claim | Evidence | Status | Non-claims |
|-------|----------|--------|------------|
| Baseline evidence ledger exists | This file was initialized. | current | Does not prove readiness, maturity, harness support, or product runtime correctness. |

## Rerun Route

Record the native validation command, Steward command, benchmark, or blocked-state route needed to refresh each current claim.
'''
        .trimLeft();
