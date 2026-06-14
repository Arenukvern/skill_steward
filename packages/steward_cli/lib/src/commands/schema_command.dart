import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../contracts/schema_contracts.dart';
import '../path_safety.dart';
import '../repo_root.dart';
import '../validation/json_schema_subset.dart';
import '../validation/steward_config.dart';
import 'blocked_command.dart';
import 'doctor_command.dart';
import 'dogfood_command.dart';
import 'ecology_command.dart';

class SchemaCommand extends Command<void> {
  SchemaCommand([
    final StringSink? outputSink,
    final Directory? startDirectory,
  ]) {
    addSubcommand(SchemaValidateCommand(outputSink, startDirectory));
    addSubcommand(SchemaCheckOutputsCommand(outputSink, startDirectory));
    addSubcommand(SchemaEmitCommand(outputSink, startDirectory));
    addSubcommand(SchemaDriftCommand(outputSink, startDirectory));
  }

  @override
  final name = 'schema';

  @override
  final description = 'Validate Steward JSON artifacts and CLI output shapes.';
}

class SchemaEmitCommand extends Command<void> {
  SchemaEmitCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'schema',
        mandatory: true,
        help: 'Schema id or alias to emit.',
      )
      ..addOption(
        'source',
        mandatory: true,
        allowed: const ['checked-in', 'generated'],
        help:
            'Whether to emit checked-in docs schema or generated model schema.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'emit';

  @override
  final description = 'Emit a checked-in or generated Steward schema.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await schemaEmitPayload(
      root,
      schemaId: argResults?['schema'] as String,
      source: argResults?['source'] as String,
    );
    _writeSchemaPayload(payload, outputSink, argResults?['json'] == true);
  }
}

class SchemaDriftCommand extends Command<void> {
  SchemaDriftCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'drift';

  @override
  final description =
      'Compare generated contract schemas with checked-in schemas.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await schemaDriftPayload(root);
    _writeSchemaPayload(payload, outputSink, argResults?['json'] == true);
  }
}

class SchemaValidateCommand extends Command<void> {
  SchemaValidateCommand([this.outputSink, this.startDirectory]) {
    argParser
      ..addFlag('json', negatable: false, help: 'Emit machine-readable JSON.')
      ..addOption(
        'schema',
        mandatory: true,
        help: 'Schema id or alias, such as doctor, mode-event, or self-model.',
      )
      ..addOption(
        'file',
        mandatory: true,
        help: 'Repository-relative JSON or JSONL file to validate.',
      );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'validate';

  @override
  final description = 'Validate one JSON or JSONL artifact against a schema.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await validateSchemaFilePayload(
      root,
      schemaId: argResults?['schema'] as String,
      filePath: argResults?['file'] as String,
    );
    _writeSchemaPayload(payload, outputSink, argResults?['json'] == true);
  }
}

class SchemaCheckOutputsCommand extends Command<void> {
  SchemaCheckOutputsCommand([this.outputSink, this.startDirectory]) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Emit machine-readable JSON.',
    );
  }

  final StringSink? outputSink;
  final Directory? startDirectory;

  @override
  final name = 'check-outputs';

  @override
  final description =
      'Run core read-only CLI payload builders against schemas.';

  @override
  Future<void> run() async {
    final root = findRepoRoot(startDirectory ?? Directory.current);
    final payload = await checkSchemaOutputsPayload(root);
    _writeSchemaPayload(payload, outputSink, argResults?['json'] == true);
  }
}

Future<Map<String, dynamic>> validateSchemaFilePayload(
  final String root, {
  required final String schemaId,
  required final String filePath,
}) async {
  final schemaName = _normalizeSchemaId(schemaId);
  final diagnostics = <String>[];

  final schema = _loadSchema(root, schemaName);
  late final String resolved;
  try {
    resolved = resolveUnderRoot(root, filePath);
  } on Object catch (error) {
    diagnostics.add(error is ArgumentError ? '${error.message}' : '$error');
    return SchemaValidatePayload(
      root: root,
      schema: schemaName,
      file: filePath,
      valid: false,
      diagnostics: diagnostics,
    ).toJson();
  }

  final file = File(resolved);
  if (!file.existsSync()) {
    diagnostics.add('${repoRelativePath(root, resolved)} is missing.');
  } else {
    diagnostics.addAll(
      _validateTextBySchema(
        schemaName,
        schema,
        await file.readAsString(),
        repoRelativePath(root, resolved),
      ),
    );
  }

  return SchemaValidatePayload(
    root: root,
    schema: schemaName,
    file: repoRelativePath(root, resolved),
    valid: diagnostics.isEmpty,
    diagnostics: diagnostics,
  ).toJson();
}

Future<Map<String, dynamic>> checkSchemaOutputsPayload(
  final String root, {
  final bool includeCompositeOutputs = true,
}) async {
  final checks = <SchemaOutputCheckPayload>[];
  final result = await StewardConfig.loadChecked(root);

  Future<void> addCheck(
    final String id,
    final String schemaName,
    final Future<Map<String, dynamic>> Function() payloadBuilder,
  ) async {
    final diagnostics = <String>[];
    var valid = false;
    try {
      final payload = await payloadBuilder();
      final schema = _loadSchema(root, schemaName);
      final result = validateJsonSchemaSubset(payload, schema);
      valid = result.valid;
      diagnostics.addAll(result.diagnostics);
    } on Object catch (error) {
      diagnostics.add('$error');
    }
    checks.add(
      SchemaOutputCheckPayload(
        id: id,
        schema: schemaName,
        valid: valid,
        diagnostics: diagnostics,
      ),
    );
  }

  await addCheck(
    'doctor',
    'doctor',
    () async => stewardDoctorPayload(root, result),
  );
  await addCheck(
    'blocked-explain',
    'blocked-explain',
    () => explainBlockedPayload(
      root,
      inputLabel: 'schema-check-outputs-fixture',
      inputJson: jsonEncode({
        'schema': 'steward/benchmark-summary/v1',
        'result': 'blocked',
        'blocked_by': 'durability_blocked',
        'durability': {
          'blocking_paths': ['steward.yaml'],
        },
      }),
    ),
  );

  if (includeCompositeOutputs) {
    await addCheck(
      'dogfood-status',
      'dogfood-status',
      () => dogfoodStatusPayload(root),
    );
    await addCheck(
      'ecology-snapshot',
      'ecology-snapshot',
      () => ecologySnapshotPayload(root),
    );
    await addCheck(
      'ecology-route',
      'ecology-route',
      () => ecologyRoutePayload(root),
    );
  }

  final valid = checks.every((final check) => check.valid);
  return SchemaCheckOutputsPayload(
    root: root,
    valid: valid,
    checks: checks,
  ).toJson();
}

Future<Map<String, dynamic>> schemaEmitPayload(
  final String root, {
  required final String schemaId,
  required final String source,
}) async {
  final schemaName = _normalizeSchemaId(schemaId);
  final diagnostics = <String>[];
  var valid = true;
  var jsonSchema = <String, dynamic>{};

  try {
    jsonSchema = source == 'generated'
        ? generatedStewardSchema(schemaName)
        : _loadSchema(root, schemaName);
  } on Object catch (error) {
    valid = false;
    diagnostics.add('$error');
  }

  return SchemaEmitPayload(
    schema: schemaName,
    source: source,
    valid: valid,
    jsonSchema: jsonSchema,
    diagnostics: diagnostics,
  ).toJson();
}

Future<Map<String, dynamic>> schemaDriftPayload(final String root) async {
  final checks = <SchemaDriftCheckPayload>[];
  final diagnostics = <String>[];

  for (final schemaName in generatedStewardSchemaNames) {
    final checkDiagnostics = <String>[];
    Map<String, dynamic>? checkedIn;
    try {
      checkedIn = _loadSchema(root, schemaName);
    } on Object catch (error) {
      checkDiagnostics.add('missing checked-in schema for $schemaName: $error');
    }

    if (checkedIn != null) {
      checkDiagnostics.addAll(
        _schemaDriftDiagnostics(
          schemaName,
          generatedStewardSchema(schemaName),
          checkedIn,
        ),
      );
    }

    checks.add(
      SchemaDriftCheckPayload(
        schema: schemaName,
        valid: checkDiagnostics.isEmpty,
        diagnostics: checkDiagnostics,
      ),
    );
    diagnostics.addAll(checkDiagnostics);
  }

  return SchemaDriftPayload(
    valid: diagnostics.isEmpty,
    checks: checks,
    diagnostics: diagnostics,
  ).toJson();
}

void _writeSchemaPayload(
  final Map<String, dynamic> payload,
  final StringSink? outputSink,
  final bool useJson,
) {
  final sink = outputSink ?? stdout;
  if (useJson) {
    sink.writeln(const JsonEncoder.withIndent('  ').convert(payload));
  } else {
    sink
      ..writeln(payload['schema_version'])
      ..writeln('- valid: ${payload['valid']}');
    final diagnostics = payload['diagnostics'];
    if (diagnostics is List) {
      for (final diagnostic in diagnostics) {
        sink.writeln('- diagnostic: $diagnostic');
      }
    }
  }
  if (payload['valid'] != true) {
    exitCode = 1;
  }
}

List<String> _schemaDriftDiagnostics(
  final String schemaName,
  final Map<String, dynamic> generated,
  final Map<String, dynamic> checkedIn,
) {
  final diagnostics = <String>[];
  final generatedProperties = _propertyKeys(generated);
  final checkedProperties = _propertyKeys(checkedIn);
  final missingInChecked = generatedProperties.difference(checkedProperties);
  final missingInGenerated = checkedProperties.difference(generatedProperties);
  if (missingInChecked.isNotEmpty) {
    diagnostics.add(
      '$schemaName properties missing in checked-in schema: ${missingInChecked.join(', ')}',
    );
  }
  if (missingInGenerated.isNotEmpty) {
    diagnostics.add(
      '$schemaName properties missing in generated schema: ${missingInGenerated.join(', ')}',
    );
  }

  final generatedRequired = _requiredKeys(generated);
  final checkedRequired = _requiredKeys(checkedIn);
  if (!_sameSet(generatedRequired, checkedRequired)) {
    diagnostics.add(
      '$schemaName required fields differ: generated=${_joinSet(generatedRequired)} checked_in=${_joinSet(checkedRequired)}',
    );
  }

  final allProperties = {...generatedProperties, ...checkedProperties};
  for (final property in allProperties) {
    final generatedEnum = _enumValues(generated, property);
    final checkedEnum = _enumValues(checkedIn, property);
    if (generatedEnum.isEmpty || checkedEnum.isEmpty) continue;
    if (!_sameSet(generatedEnum, checkedEnum)) {
      diagnostics.add(
        '$schemaName.$property enum differs: generated=${_joinSet(generatedEnum)} checked_in=${_joinSet(checkedEnum)}',
      );
    }
  }

  return diagnostics;
}

Set<String> _propertyKeys(final Map<String, dynamic> schema) {
  final properties = schema['properties'];
  if (properties is! Map) return const {};
  return properties.keys.whereType<String>().toSet();
}

Set<String> _requiredKeys(final Map<String, dynamic> schema) {
  final required = schema['required'];
  if (required is! List) return const {};
  return required.whereType<String>().toSet();
}

Set<String> _enumValues(
  final Map<String, dynamic> schema,
  final String property,
) {
  final properties = schema['properties'];
  if (properties is! Map) return const {};
  final propertySchema = properties[property];
  if (propertySchema is! Map) return const {};
  final enumValues = propertySchema['enum'];
  if (enumValues is! List) return const {};
  return enumValues.map((final value) => '$value').toSet();
}

bool _sameSet(final Set<String> a, final Set<String> b) =>
    a.length == b.length && a.containsAll(b);

String _joinSet(final Set<String> values) {
  final sorted = values.toList()..sort();
  return sorted.join(',');
}

List<String> _validateTextBySchema(
  final String schemaName,
  final Map<String, dynamic> schema,
  final String text,
  final String label,
) {
  final diagnostics = <String>[];
  final isJsonl = schemaName == 'mode-event' || label.endsWith('.jsonl');
  if (isJsonl) {
    final lines = const LineSplitter().convert(text);
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) continue;
      diagnostics.addAll(
        _validateJsonText(schema, line, '$label:${index + 1}'),
      );
    }
  } else {
    diagnostics.addAll(_validateJsonText(schema, text, label));
  }
  return diagnostics;
}

List<String> _validateJsonText(
  final Map<String, dynamic> schema,
  final String text,
  final String label,
) {
  try {
    final decoded = jsonDecode(text);
    return validateJsonSchemaSubset(
      decoded,
      schema,
    ).diagnostics.map((final diagnostic) => '$label: $diagnostic').toList();
  } on FormatException catch (error) {
    return ['$label: invalid JSON: ${error.message}'];
  }
}

Map<String, dynamic> _loadSchema(final String root, final String schemaName) {
  final schemaPath = p.join(
    _findSchemaDirectory(root),
    _schemaFile(schemaName),
  );
  return jsonDecode(File(schemaPath).readAsStringSync())
      as Map<String, dynamic>;
}

String _findSchemaDirectory(final String root) {
  final envSchemas = Platform.environment['STEWARD_SCHEMA_DIR'];
  if (envSchemas != null && envSchemas.trim().isNotEmpty) {
    final candidate = Directory(envSchemas);
    if (candidate.existsSync()) return candidate.path;
  }

  final rootSchemas = Directory(p.join(root, 'docs', 'schemas'));
  if (rootSchemas.existsSync()) return rootSchemas.path;

  final executableDir = p.dirname(Platform.resolvedExecutable);
  for (final path in [
    p.join(executableDir, 'steward_schemas'),
    p.join(executableDir, 'docs', 'schemas'),
    p.join(p.dirname(executableDir), 'docs', 'schemas'),
  ]) {
    final candidate = Directory(path);
    if (candidate.existsSync()) return candidate.path;
  }

  var cursor = Directory.current;
  while (true) {
    final candidate = Directory(p.join(cursor.path, 'docs', 'schemas'));
    if (candidate.existsSync()) return candidate.path;
    final parent = cursor.parent;
    if (parent.path == cursor.path) break;
    cursor = parent;
  }
  throw StateError('Could not locate docs/schemas directory.');
}

String _normalizeSchemaId(final String schemaId) => switch (schemaId.trim()) {
  'steward/action-candidate/v1' || 'action-candidate-v1' => 'action-candidate',
  'steward/adoption-run/v2' || 'adoption-run-v2' => 'adoption-run',
  'steward/benchmark-summary/v1' ||
  'benchmark-summary-v1' => 'benchmark-summary',
  'steward/experiment-campaign-summary/v1' ||
  'experiment-campaign-summary-v1' => 'experiment-campaign-summary',
  'steward.dogfood.status.v1' || 'dogfood-status-v1' => 'dogfood-status',
  'steward.ecology.snapshot.v1' || 'ecology-snapshot-v1' => 'ecology-snapshot',
  'steward.ecology.route.v1' || 'ecology-route-v1' => 'ecology-route',
  'steward.claim.check.v1' || 'claim-check-v1' => 'claim-check',
  'steward.blocked.explain.v1' || 'blocked-explain-v1' => 'blocked-explain',
  'steward.schema.validate.v1' || 'schema-validate-v1' => 'schema-validate',
  'steward.schema.check_outputs.v1' ||
  'schema-check-outputs-v1' => 'schema-check-outputs',
  'steward.schema.emit.v1' || 'schema-emit-v1' => 'schema-emit',
  'steward.schema.drift.v1' || 'schema-drift-v1' => 'schema-drift',
  'steward.protocol.validate.v1' ||
  'protocol-validate-v1' => 'protocol-validate',
  'doctor-v1' || 'steward.doctor.v1' => 'doctor',
  'mode-event-v1' || 'steward/mode-event/v1' => 'mode-event',
  'steward/observation/v1' || 'observation-v1' => 'observation',
  'steward/plugin-bundle-index/v1' ||
  'plugin-bundle-index-v1' => 'plugin-bundle-index',
  'steward/plugin-bundle/v1' || 'plugin-bundle-v1' => 'plugin-bundle',
  'steward/plugin-manifest/v1' || 'plugin-manifest-v1' => 'plugin-manifest',
  'steward/scenario-manifest/v1' ||
  'scenario-manifest-v1' => 'scenario-manifest',
  'self-model-v1' || 'steward/self-model/v1' => 'self-model',
  'steward/v1' || 'steward-v1' => 'steward',
  'unknown-case-v1' || 'steward/unknown-case/v1' => 'unknown-case',
  final value => value,
};

String _schemaFile(final String schemaName) => switch (schemaName) {
  'action-candidate' => 'action-candidate-v1.schema.json',
  'adoption-run' => 'adoption-run-v2.schema.json',
  'benchmark-summary' => 'benchmark-summary-v1.schema.json',
  'experiment-campaign-summary' => 'experiment-campaign-summary-v1.schema.json',
  'dogfood-status' => 'dogfood-status-v1.schema.json',
  'ecology-snapshot' => 'ecology-snapshot-v1.schema.json',
  'ecology-route' => 'ecology-route-v1.schema.json',
  'claim-check' => 'claim-check-v1.schema.json',
  'blocked-explain' => 'blocked-explain-v1.schema.json',
  'schema-validate' => 'schema-validate-v1.schema.json',
  'schema-check-outputs' => 'schema-check-outputs-v1.schema.json',
  'schema-emit' => 'schema-emit-v1.schema.json',
  'schema-drift' => 'schema-drift-v1.schema.json',
  'protocol-validate' => 'protocol-validate-v1.schema.json',
  'doctor' => 'doctor-v1.schema.json',
  'mode-event' => 'mode-event-v1.schema.json',
  'observation' => 'observation-v1.schema.json',
  'plugin-bundle-index' => 'plugin-bundle-index-v1.schema.json',
  'plugin-bundle' => 'plugin-bundle-v1.schema.json',
  'plugin-manifest' => 'plugin-manifest-v1.schema.json',
  'scenario-manifest' => 'scenario-manifest-v1.schema.json',
  'self-model' => 'self-model-v1.schema.json',
  'steward' => 'steward-v1.schema.json',
  'unknown-case' => 'unknown-case-v1.schema.json',
  _ => throw UsageException('Unknown schema: $schemaName', ''),
};
