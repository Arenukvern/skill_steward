// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimCheckPayload _$ClaimCheckPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ClaimCheckPayload',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'schema_version',
            'claim',
            'valid',
            'result',
            'accepted',
            'diagnostics',
            'non_claims',
          ],
          requiredKeys: const ['schema_version'],
        );
        final val = ClaimCheckPayload(
          claim: $checkedConvert('claim', (v) => v as String),
          valid: $checkedConvert('valid', (v) => v as bool),
          diagnostics: $checkedConvert(
            'diagnostics',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          nonClaims: $checkedConvert(
            'non_claims',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          schemaVersion: $checkedConvert(
            'schema_version',
            (v) => v as String? ?? 'steward.claim.check.v1',
          ),
          result: $checkedConvert('result', (v) => v as String?),
          accepted: $checkedConvert('accepted', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'nonClaims': 'non_claims',
        'schemaVersion': 'schema_version',
      },
    );

Map<String, dynamic> _$ClaimCheckPayloadToJson(ClaimCheckPayload instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'claim': instance.claim,
      'valid': instance.valid,
      'result': instance.result,
      'accepted': instance.accepted,
      'diagnostics': instance.diagnostics,
      'non_claims': instance.nonClaims,
    };

const _$ClaimCheckPayloadJsonSchema = {
  r'$schema': 'https://json-schema.org/draft/2020-12/schema',
  'type': 'object',
  'properties': {
    'schema_version': {'type': 'string', 'default': 'steward.claim.check.v1'},
    'claim': {'type': 'string'},
    'valid': {'type': 'boolean'},
    'result': {'type': 'string'},
    'accepted': {'type': 'boolean'},
    'diagnostics': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'non_claims': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['schema_version', 'claim', 'valid', 'diagnostics', 'non_claims'],
};
