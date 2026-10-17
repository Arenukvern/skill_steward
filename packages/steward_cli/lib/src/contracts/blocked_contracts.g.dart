// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlockedExplanationPayload _$BlockedExplanationPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BlockedExplanationPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'schema_version',
        'guidance',
        'root',
        'input',
        'blocked_by',
        'artifact_route',
        'next_actions',
        'non_claims',
      ],
      requiredKeys: const ['schema_version'],
    );
    final val = BlockedExplanationPayload(
      root: $checkedConvert('root', (v) => v as String),
      input: $checkedConvert('input', (v) => v as String),
      blockedBy: $checkedConvert('blocked_by', (v) => v as String),
      artifactRoute: $checkedConvert('artifact_route', (v) => v as String),
      nextActions: $checkedConvert(
        'next_actions',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      nonClaims: $checkedConvert(
        'non_claims',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      guidance: $checkedConvert(
        'guidance',
        (v) => v == null
            ? null
            : OutputGuidancePayload.fromJson(v as Map<String, dynamic>),
      ),
      schemaVersion: $checkedConvert(
        'schema_version',
        (v) => v as String? ?? 'steward.blocked.explain.v1',
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'blockedBy': 'blocked_by',
    'artifactRoute': 'artifact_route',
    'nextActions': 'next_actions',
    'nonClaims': 'non_claims',
    'schemaVersion': 'schema_version',
  },
);

Map<String, dynamic> _$BlockedExplanationPayloadToJson(
  BlockedExplanationPayload instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'guidance': ?instance.guidance?.toJson(),
  'root': instance.root,
  'input': instance.input,
  'blocked_by': instance.blockedBy,
  'artifact_route': instance.artifactRoute,
  'next_actions': instance.nextActions,
  'non_claims': instance.nonClaims,
};

const _$BlockedExplanationPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {
      'type': 'string',
      'default': 'steward.blocked.explain.v1',
    },
    'guidance': {r'$ref': r'#/$defs/OutputGuidancePayload'},
    'root': {'type': 'string'},
    'input': {'type': 'string'},
    'blocked_by': {'type': 'string'},
    'artifact_route': {'type': 'string'},
    'next_actions': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'non_claims': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': [
    'schema_version',
    'root',
    'input',
    'blocked_by',
    'artifact_route',
    'next_actions',
    'non_claims',
  ],
  r'$defs': {
    'OutputGuidancePayload': {
      'type': 'object',
      'properties': {
        'schema_version': {
          'type': 'string',
          'default': 'steward.output-guidance.v1',
        },
        'advisory': {'type': 'boolean', 'default': true},
        'original_goal': {'type': 'string'},
        'source_revision': {'type': 'string'},
        'observation': {'type': 'string'},
        'basis': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'uncertainty': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'next_step': {'type': 'string'},
        'next_argv': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'precondition': {'type': 'string'},
        'verify_argv': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'verify_expected': {'type': 'string'},
        'return_to_goal': {'type': 'string'},
        'expand': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': [
        'observation',
        'basis',
        'uncertainty',
        'next_step',
        'precondition',
        'verify_expected',
        'return_to_goal',
        'expand',
      ],
    },
  },
};
