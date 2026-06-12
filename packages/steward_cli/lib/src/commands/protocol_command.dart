import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../contracts/protocol_contracts.dart';
import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/protocol_validator.dart';

class ProtocolCommand extends Command<void> {
  ProtocolCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(ProtocolValidateCommand(outputSink, startDirectory));
  }

  @override
  final name = 'protocol';

  @override
  final description = 'Validate stewardship protocol artifacts.';
}

class ProtocolValidateCommand extends Command<void> {
  ProtocolValidateCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'mode-events',
        mandatory: true,
        help: 'Path to a JSONL file of steward/mode-event/v1 records.',
      )
      ..addOption(
        'self-model',
        mandatory: true,
        help: 'Path to a steward/self-model/v1 JSON file.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'validate';

  @override
  final description = 'Validate mode events and self-model protocol artifacts.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await validateProtocolPayload(
      root,
      modeEventsPath: argResults?['mode-events'] as String,
      selfModelPath: argResults?['self-model'] as String,
    );
    final valid = payload['valid'] == true;
    final sink = outputSink ?? stdout;

    if (argResults?['json'] == true) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
    } else {
      sink
        ..writeln('Steward protocol validation')
        ..writeln('- valid: $valid');
      for (final diagnostic in payload['diagnostics'] as List) {
        sink.writeln('- diagnostic: $diagnostic');
      }
    }

    if (!valid) {
      exitCode = 1;
    }
  }
}

Future<Map<String, dynamic>> validateProtocolPayload(
  final String root, {
  required final String modeEventsPath,
  required final String selfModelPath,
}) async {
  const validator = ProtocolValidator();
  final diagnostics = <String>[];
  final files = <String, dynamic>{};

  await _validateModeEventsFile(
    root,
    modeEventsPath,
    validator,
    diagnostics,
    files,
  );
  await _validateSelfModelFile(
    root,
    selfModelPath,
    validator,
    diagnostics,
    files,
  );

  return ProtocolValidatePayload(
    root: root,
    valid: diagnostics.isEmpty,
    diagnostics: diagnostics,
    files: files,
  ).toJson();
}

Future<void> _validateModeEventsFile(
  final String root,
  final String path,
  final ProtocolValidator validator,
  final List<String> diagnostics,
  final Map<String, dynamic> files,
) async {
  final input = await _readRootedFile(root, path);
  files['mode_events'] = {
    'path': input.relativePath,
    'exists': input.text != null,
    'events': 0,
  };
  final text = input.text;
  if (text == null) {
    diagnostics.add(input.diagnostic ?? '${input.relativePath}: missing file.');
    return;
  }

  diagnostics.addAll(
    validator
        .validateNoRawPrivateMaterial(text)
        .map((final diagnostic) => '${input.relativePath}: $diagnostic'),
  );

  var eventCount = 0;
  final lines = const LineSplitter().convert(text);
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) continue;
    eventCount++;
    final label = '${input.relativePath}:${index + 1}';
    Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException catch (error) {
      diagnostics.add('$label: invalid JSON: ${error.message}');
      continue;
    }
    if (decoded is! Map) {
      diagnostics.add('$label: mode event must be a JSON object.');
      continue;
    }
    late final ModeEventContract event;
    try {
      event = ModeEventContract.fromJson(Map<String, dynamic>.from(decoded));
    } on Object catch (error) {
      diagnostics.add('$label: $error');
      continue;
    }
    diagnostics.addAll(
      validator
          .validateModeEvent(event.toJson())
          .map((final diagnostic) => '$label: $diagnostic'),
    );
  }

  (files['mode_events'] as Map<String, dynamic>)['events'] = eventCount;
}

Future<void> _validateSelfModelFile(
  final String root,
  final String path,
  final ProtocolValidator validator,
  final List<String> diagnostics,
  final Map<String, dynamic> files,
) async {
  final input = await _readRootedFile(root, path);
  files['self_model'] = {
    'path': input.relativePath,
    'exists': input.text != null,
  };
  final text = input.text;
  if (text == null) {
    diagnostics.add(input.diagnostic ?? '${input.relativePath}: missing file.');
    return;
  }

  diagnostics.addAll(
    validator
        .validateNoRawPrivateMaterial(text)
        .map((final diagnostic) => '${input.relativePath}: $diagnostic'),
  );

  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    diagnostics.add('${input.relativePath}: invalid JSON: ${error.message}');
    return;
  }
  if (decoded is! Map) {
    diagnostics.add('${input.relativePath}: self-model must be a JSON object.');
    return;
  }
  late final SelfModelContract selfModel;
  try {
    selfModel = SelfModelContract.fromJson(Map<String, dynamic>.from(decoded));
  } on Object catch (error) {
    diagnostics.add('${input.relativePath}: $error');
    return;
  }
  diagnostics.addAll(
    validator
        .validateSelfModel(selfModel.toJson())
        .map((final diagnostic) => '${input.relativePath}: $diagnostic'),
  );
}

Future<_ProtocolFileInput> _readRootedFile(
  final String root,
  final String path,
) async {
  late final String resolved;
  try {
    resolved = resolveUnderRoot(root, path);
  } on Object catch (error) {
    final diagnostic = error is ArgumentError
        ? '${error.message}'
        : error.toString();
    return _ProtocolFileInput(relativePath: path, diagnostic: diagnostic);
  }

  final relativePath = repoRelativePath(root, resolved);
  final file = File(resolved);
  if (!file.existsSync()) {
    return _ProtocolFileInput(
      relativePath: relativePath,
      diagnostic: '$relativePath: missing file.',
    );
  }
  return _ProtocolFileInput(
    relativePath: relativePath,
    text: await file.readAsString(),
  );
}

class _ProtocolFileInput {
  const _ProtocolFileInput({
    required this.relativePath,
    this.text,
    this.diagnostic,
  });

  final String relativePath;
  final String? text;
  final String? diagnostic;
}
