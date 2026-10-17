// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output_guidance_contract.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutputGuidancePayload _$OutputGuidancePayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'OutputGuidancePayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'schema_version',
        'advisory',
        'original_goal',
        'source_revision',
        'observation',
        'basis',
        'uncertainty',
        'next_step',
        'next_argv',
        'precondition',
        'verify_argv',
        'verify_expected',
        'return_to_goal',
        'expand',
      ],
    );
    final val = OutputGuidancePayload(
      observation: $checkedConvert('observation', (v) => v as String),
      basis: $checkedConvert(
        'basis',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      uncertainty: $checkedConvert(
        'uncertainty',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      nextStep: $checkedConvert('next_step', (v) => v as String),
      precondition: $checkedConvert('precondition', (v) => v as String),
      verifyExpected: $checkedConvert('verify_expected', (v) => v as String),
      returnToGoal: $checkedConvert('return_to_goal', (v) => v as String),
      expand: $checkedConvert(
        'expand',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      originalGoal: $checkedConvert('original_goal', (v) => v as String?),
      sourceRevision: $checkedConvert('source_revision', (v) => v as String?),
      nextArgv: $checkedConvert(
        'next_argv',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      verifyArgv: $checkedConvert(
        'verify_argv',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      schemaVersion: $checkedConvert(
        'schema_version',
        (v) => v as String? ?? 'steward.output-guidance.v1',
      ),
      advisory: $checkedConvert('advisory', (v) => v as bool? ?? true),
    );
    return val;
  },
  fieldKeyMap: const {
    'nextStep': 'next_step',
    'verifyExpected': 'verify_expected',
    'returnToGoal': 'return_to_goal',
    'originalGoal': 'original_goal',
    'sourceRevision': 'source_revision',
    'nextArgv': 'next_argv',
    'verifyArgv': 'verify_argv',
    'schemaVersion': 'schema_version',
  },
);

Map<String, dynamic> _$OutputGuidancePayloadToJson(
  OutputGuidancePayload instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'advisory': instance.advisory,
  'original_goal': ?instance.originalGoal,
  'source_revision': ?instance.sourceRevision,
  'observation': instance.observation,
  'basis': instance.basis,
  'uncertainty': instance.uncertainty,
  'next_step': instance.nextStep,
  'next_argv': ?instance.nextArgv,
  'precondition': instance.precondition,
  'verify_argv': ?instance.verifyArgv,
  'verify_expected': instance.verifyExpected,
  'return_to_goal': instance.returnToGoal,
  'expand': instance.expand,
};

const _$OutputGuidancePayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
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
};
