import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../repo_root.dart';
import 'ecology_command.dart';

class DogfoodCommand extends Command<void> {
  DogfoodCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(DogfoodStatusCommand(outputSink, startDirectory));
  }

  @override
  final name = 'dogfood';

  @override
  final description =
      'Compose current dogfood status without awarding maturity.';
}

class DogfoodStatusCommand extends Command<void> {
  DogfoodStatusCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'status';

  @override
  final description =
      'Compose current ledger, ecology inventory, and next routing hints.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await dogfoodStatusPayload(root);
    final sink = outputSink ?? stdout;

    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
      return;
    }

    sink
      ..writeln('Steward dogfood status')
      ..writeln('- root: ${payload['root']}')
      ..writeln('- status: ${payload['status']}');
    for (final action in payload['next_actions'] as List) {
      sink.writeln('- next: $action');
    }
  }
}

Future<Map<String, dynamic>> dogfoodStatusPayload(final String root) async {
  final ecology = await ecologySnapshotPayload(root);
  final ledger = _currentLedger(root);
  final config = ecology['config'] as Map? ?? const {};
  final schemaOutputs = ecology['schema_outputs'] as Map? ?? const {};
  final benchmarks = ecology['benchmarks'] as Map? ?? const {};
  final ledgerFrontmatter =
      (ledger['frontmatter'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};

  return {
    'schema_version': 'steward.dogfood.status.v1',
    'root': root,
    'status': 'observed',
    'current_ledger': ledger,
    'ecology': {
      'config_valid': config['valid'] == true,
      'schema_outputs_valid': schemaOutputs['valid'] == true,
      'git_status': (ecology['git'] as Map?)?['status'],
      'current_dogfood_status_present':
          (ecology['evidence'] as Map?)?['current_dogfood_status_present'] ==
          true,
      'persisted_summaries_status': benchmarks['summary_status'],
      'persisted_summaries_may_be_stale':
          benchmarks['summaries_may_be_stale'] == true,
    },
    'weakest_current_claim': {
      'claim_tested': ledgerFrontmatter['claim_tested'],
      'proof_level': ledgerFrontmatter['proof_level'],
      'result': ledgerFrontmatter['result'],
      'limitations': ledgerFrontmatter['limitations'],
      'non_claims': ledgerFrontmatter['non_claims'] ?? const [],
    },
    'next_actions': _nextActions(ecology, ledger),
    'non_claims': const [
      'This command composes current routing facts; it does not award maturity.',
      'This command does not prove H2, H4, H5, S5, adoption, or steward status.',
      'Historical evidence remains provenance unless the current ledger says it still holds.',
    ],
  };
}

Map<String, dynamic> _currentLedger(final String root) {
  final file = File(
    p.join(root, 'docs', 'evidence', 'current-dogfood-status.mdx'),
  );
  if (!file.existsSync()) {
    return {
      'present': false,
      'path': 'docs/evidence/current-dogfood-status.mdx',
      'frontmatter': <String, dynamic>{},
    };
  }

  final content = file.readAsStringSync();
  return {
    'present': true,
    'path': p.relative(file.path, from: root).replaceAll(r'\', '/'),
    'frontmatter': _frontmatter(content),
  };
}

Map<String, dynamic> _frontmatter(final String content) {
  final lines = const LineSplitter().convert(content);
  if (lines.isEmpty || lines.first.trim() != '---') return {};

  final map = <String, dynamic>{};
  String? currentListKey;
  for (final line in lines.skip(1)) {
    if (line.trim() == '---') break;
    if (line.startsWith('  - ') && currentListKey != null) {
      (map[currentListKey] as List<String>).add(line.substring(4).trim());
      continue;
    }

    final separator = line.indexOf(':');
    if (separator <= 0) {
      currentListKey = null;
      continue;
    }

    final key = line.substring(0, separator).trim();
    final value = line.substring(separator + 1).trim();
    if (value.isEmpty) {
      map[key] = <String>[];
      currentListKey = key;
    } else {
      map[key] = value;
      currentListKey = null;
    }
  }
  return map;
}

List<String> _nextActions(
  final Map<String, dynamic> ecology,
  final Map<String, dynamic> ledger,
) {
  final actions = <String>[];
  if (ledger['present'] != true) {
    actions.add(
      'Create a current ledger: steward evidence init --minimal or docs/evidence/current-dogfood-status.mdx.',
    );
  }

  final config = ecology['config'] as Map? ?? const {};
  if (config['valid'] != true) {
    actions.add(
      'Repair steward.yaml diagnostics before claiming dogfood proof.',
    );
  }

  final schemaOutputs = ecology['schema_outputs'] as Map? ?? const {};
  if (schemaOutputs['valid'] != true) {
    actions.add(
      'Repair schema/output drift before relying on machine-readable dogfood status.',
    );
  }

  final benchmarks = ecology['benchmarks'] as Map? ?? const {};
  if (benchmarks['summaries_may_be_stale'] == true) {
    actions.add(
      'Treat persisted benchmark summaries as history; rerun the exact benchmark for current proof.',
    );
  }

  if (actions.isEmpty) {
    actions.add('Use the current ledger to choose the next exact rerun route.');
  }
  return actions;
}
