import 'package:json_annotation/json_annotation.dart';

import 'blocked_contracts.dart';
import 'claim_contracts.dart';
import 'protocol_contracts.dart';

part 'schema_contracts.g.dart';

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class SchemaValidatePayload {
  const SchemaValidatePayload({
    required this.root,
    required this.schema,
    required this.file,
    required this.valid,
    required this.diagnostics,
    this.schemaVersion = 'steward.schema.validate.v1',
  });

  factory SchemaValidatePayload.fromJson(final Map<String, dynamic> json) =>
      _$SchemaValidatePayloadFromJson(json);

  static const generatedSchema = _$SchemaValidatePayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final String root;
  final String schema;
  final String file;
  final bool valid;
  final List<String> diagnostics;

  Map<String, dynamic> toJson() => _$SchemaValidatePayloadToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
class SchemaCheckOutputsPayload {
  const SchemaCheckOutputsPayload({
    required this.root,
    required this.valid,
    required this.checks,
    this.schemaVersion = 'steward.schema.check_outputs.v1',
  });

  factory SchemaCheckOutputsPayload.fromJson(final Map<String, dynamic> json) =>
      _$SchemaCheckOutputsPayloadFromJson(json);

  static const generatedSchema = _$SchemaCheckOutputsPayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final String root;
  final bool valid;
  final List<SchemaOutputCheckPayload> checks;

  Map<String, dynamic> toJson() => _$SchemaCheckOutputsPayloadToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class SchemaOutputCheckPayload {
  const SchemaOutputCheckPayload({
    required this.id,
    required this.schema,
    required this.valid,
    required this.diagnostics,
  });

  factory SchemaOutputCheckPayload.fromJson(final Map<String, dynamic> json) =>
      _$SchemaOutputCheckPayloadFromJson(json);

  final String id;
  final String schema;
  final bool valid;
  final List<String> diagnostics;

  Map<String, dynamic> toJson() => _$SchemaOutputCheckPayloadToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class SchemaEmitPayload {
  const SchemaEmitPayload({
    required this.schema,
    required this.source,
    required this.valid,
    required this.jsonSchema,
    required this.diagnostics,
    this.schemaVersion = 'steward.schema.emit.v1',
  });

  factory SchemaEmitPayload.fromJson(final Map<String, dynamic> json) =>
      _$SchemaEmitPayloadFromJson(json);

  static const generatedSchema = _$SchemaEmitPayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final String schema;
  final String source;
  final bool valid;
  @JsonKey(name: 'json_schema')
  final Map<String, dynamic> jsonSchema;
  final List<String> diagnostics;

  Map<String, dynamic> toJson() => _$SchemaEmitPayloadToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
class SchemaDriftPayload {
  const SchemaDriftPayload({
    required this.valid,
    required this.checks,
    required this.diagnostics,
    this.schemaVersion = 'steward.schema.drift.v1',
  });

  factory SchemaDriftPayload.fromJson(final Map<String, dynamic> json) =>
      _$SchemaDriftPayloadFromJson(json);

  static const generatedSchema = _$SchemaDriftPayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final bool valid;
  final List<SchemaDriftCheckPayload> checks;
  final List<String> diagnostics;

  Map<String, dynamic> toJson() => _$SchemaDriftPayloadToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class SchemaDriftCheckPayload {
  const SchemaDriftCheckPayload({
    required this.schema,
    required this.valid,
    required this.diagnostics,
  });

  factory SchemaDriftCheckPayload.fromJson(final Map<String, dynamic> json) =>
      _$SchemaDriftCheckPayloadFromJson(json);

  final String schema;
  final bool valid;
  final List<String> diagnostics;

  Map<String, dynamic> toJson() => _$SchemaDriftCheckPayloadToJson(this);
}

Map<String, dynamic> generatedStewardSchema(final String schemaName) {
  final schema = switch (schemaName.trim()) {
    'claim-check' => ClaimCheckPayload.generatedSchema,
    'blocked-explain' => BlockedExplanationPayload.generatedSchema,
    'schema-validate' => SchemaValidatePayload.generatedSchema,
    'schema-check-outputs' => SchemaCheckOutputsPayload.generatedSchema,
    'schema-emit' => SchemaEmitPayload.generatedSchema,
    'schema-drift' => SchemaDriftPayload.generatedSchema,
    'mode-event' => ModeEventContract.generatedSchema,
    'self-model' => SelfModelContract.generatedSchema,
    'protocol-validate' => ProtocolValidatePayload.generatedSchema,
    _ => throw ArgumentError.value(schemaName, 'schemaName', 'Unknown schema'),
  };
  return Map<String, dynamic>.from(schema);
}

List<String> get generatedStewardSchemaNames => const [
  'claim-check',
  'blocked-explain',
  'schema-validate',
  'schema-check-outputs',
  'schema-emit',
  'schema-drift',
  'mode-event',
  'self-model',
  'protocol-validate',
];
