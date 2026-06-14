// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemaValidatePayload _$SchemaValidatePayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SchemaValidatePayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'schema_version',
        'root',
        'schema',
        'file',
        'valid',
        'diagnostics',
      ],
      requiredKeys: const ['schema_version'],
    );
    final val = SchemaValidatePayload(
      root: $checkedConvert('root', (v) => v as String),
      schema: $checkedConvert('schema', (v) => v as String),
      file: $checkedConvert('file', (v) => v as String),
      valid: $checkedConvert('valid', (v) => v as bool),
      diagnostics: $checkedConvert(
        'diagnostics',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      schemaVersion: $checkedConvert(
        'schema_version',
        (v) => v as String? ?? 'steward.schema.validate.v1',
      ),
    );
    return val;
  },
  fieldKeyMap: const {'schemaVersion': 'schema_version'},
);

Map<String, dynamic> _$SchemaValidatePayloadToJson(
  SchemaValidatePayload instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'root': instance.root,
  'schema': instance.schema,
  'file': instance.file,
  'valid': instance.valid,
  'diagnostics': instance.diagnostics,
};

const _$SchemaValidatePayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {
      'type': 'string',
      'default': 'steward.schema.validate.v1',
    },
    'root': {'type': 'string'},
    'schema': {'type': 'string'},
    'file': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': [
    'schema_version',
    'root',
    'schema',
    'file',
    'valid',
    'diagnostics',
  ],
};

SchemaCheckOutputsPayload _$SchemaCheckOutputsPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SchemaCheckOutputsPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const ['schema_version', 'root', 'valid', 'checks'],
      requiredKeys: const ['schema_version'],
    );
    final val = SchemaCheckOutputsPayload(
      root: $checkedConvert('root', (v) => v as String),
      valid: $checkedConvert('valid', (v) => v as bool),
      checks: $checkedConvert(
        'checks',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  SchemaOutputCheckPayload.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      schemaVersion: $checkedConvert(
        'schema_version',
        (v) => v as String? ?? 'steward.schema.check_outputs.v1',
      ),
    );
    return val;
  },
  fieldKeyMap: const {'schemaVersion': 'schema_version'},
);

Map<String, dynamic> _$SchemaCheckOutputsPayloadToJson(
  SchemaCheckOutputsPayload instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'root': instance.root,
  'valid': instance.valid,
  'checks': instance.checks.map((e) => e.toJson()).toList(),
};

const _$SchemaCheckOutputsPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {
      'type': 'string',
      'default': 'steward.schema.check_outputs.v1',
    },
    'root': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'checks': {
      'type': 'array',
      'items': {r'$ref': r'#/$defs/SchemaOutputCheckPayload'},
    },
  },
  'required': ['schema_version', 'root', 'valid', 'checks'],
  r'$defs': {
    'SchemaOutputCheckPayload': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
        'schema': {'type': 'string'},
        'valid': {'type': 'boolean'},
        'diagnostics': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['id', 'schema', 'valid', 'diagnostics'],
    },
  },
};

SchemaOutputCheckPayload _$SchemaOutputCheckPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SchemaOutputCheckPayload', json, ($checkedConvert) {
  $checkKeys(json, allowedKeys: const ['id', 'schema', 'valid', 'diagnostics']);
  final val = SchemaOutputCheckPayload(
    id: $checkedConvert('id', (v) => v as String),
    schema: $checkedConvert('schema', (v) => v as String),
    valid: $checkedConvert('valid', (v) => v as bool),
    diagnostics: $checkedConvert(
      'diagnostics',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SchemaOutputCheckPayloadToJson(
  SchemaOutputCheckPayload instance,
) => <String, dynamic>{
  'id': instance.id,
  'schema': instance.schema,
  'valid': instance.valid,
  'diagnostics': instance.diagnostics,
};

const _$SchemaOutputCheckPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'id': {'type': 'string'},
    'schema': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['id', 'schema', 'valid', 'diagnostics'],
};

SchemaEmitPayload _$SchemaEmitPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SchemaEmitPayload',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'schema_version',
            'schema',
            'source',
            'valid',
            'json_schema',
            'diagnostics',
          ],
          requiredKeys: const ['schema_version'],
        );
        final val = SchemaEmitPayload(
          schema: $checkedConvert('schema', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String),
          valid: $checkedConvert('valid', (v) => v as bool),
          jsonSchema: $checkedConvert(
            'json_schema',
            (v) => v as Map<String, dynamic>,
          ),
          diagnostics: $checkedConvert(
            'diagnostics',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          schemaVersion: $checkedConvert(
            'schema_version',
            (v) => v as String? ?? 'steward.schema.emit.v1',
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'jsonSchema': 'json_schema',
        'schemaVersion': 'schema_version',
      },
    );

Map<String, dynamic> _$SchemaEmitPayloadToJson(SchemaEmitPayload instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'schema': instance.schema,
      'source': instance.source,
      'valid': instance.valid,
      'json_schema': instance.jsonSchema,
      'diagnostics': instance.diagnostics,
    };

const _$SchemaEmitPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {'type': 'string', 'default': 'steward.schema.emit.v1'},
    'schema': {'type': 'string'},
    'source': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'json_schema': {
      'type': 'object',
      'additionalProperties': {'type': 'object'},
    },
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': [
    'schema_version',
    'schema',
    'source',
    'valid',
    'json_schema',
    'diagnostics',
  ],
};

SchemaDriftPayload _$SchemaDriftPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SchemaDriftPayload', json, ($checkedConvert) {
      $checkKeys(
        json,
        allowedKeys: const ['schema_version', 'valid', 'checks', 'diagnostics'],
        requiredKeys: const ['schema_version'],
      );
      final val = SchemaDriftPayload(
        valid: $checkedConvert('valid', (v) => v as bool),
        checks: $checkedConvert(
          'checks',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    SchemaDriftCheckPayload.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        diagnostics: $checkedConvert(
          'diagnostics',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        schemaVersion: $checkedConvert(
          'schema_version',
          (v) => v as String? ?? 'steward.schema.drift.v1',
        ),
      );
      return val;
    }, fieldKeyMap: const {'schemaVersion': 'schema_version'});

Map<String, dynamic> _$SchemaDriftPayloadToJson(SchemaDriftPayload instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'valid': instance.valid,
      'checks': instance.checks.map((e) => e.toJson()).toList(),
      'diagnostics': instance.diagnostics,
    };

const _$SchemaDriftPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {'type': 'string', 'default': 'steward.schema.drift.v1'},
    'valid': {'type': 'boolean'},
    'checks': {
      'type': 'array',
      'items': {r'$ref': r'#/$defs/SchemaDriftCheckPayload'},
    },
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['schema_version', 'valid', 'checks', 'diagnostics'],
  r'$defs': {
    'SchemaDriftCheckPayload': {
      'type': 'object',
      'properties': {
        'schema': {'type': 'string'},
        'valid': {'type': 'boolean'},
        'diagnostics': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['schema', 'valid', 'diagnostics'],
    },
  },
};

SchemaDriftCheckPayload _$SchemaDriftCheckPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SchemaDriftCheckPayload', json, ($checkedConvert) {
  $checkKeys(json, allowedKeys: const ['schema', 'valid', 'diagnostics']);
  final val = SchemaDriftCheckPayload(
    schema: $checkedConvert('schema', (v) => v as String),
    valid: $checkedConvert('valid', (v) => v as bool),
    diagnostics: $checkedConvert(
      'diagnostics',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$SchemaDriftCheckPayloadToJson(
  SchemaDriftCheckPayload instance,
) => <String, dynamic>{
  'schema': instance.schema,
  'valid': instance.valid,
  'diagnostics': instance.diagnostics,
};

const _$SchemaDriftCheckPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['schema', 'valid', 'diagnostics'],
};
