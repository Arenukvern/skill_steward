import 'package:json_annotation/json_annotation.dart';

part 'claim_contracts.g.dart';

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class ClaimCheckPayload {
  ClaimCheckPayload({
    required this.claim,
    required this.valid,
    required this.diagnostics,
    required this.nonClaims,
    this.schemaVersion = 'steward.claim.check.v1',
    final String? result,
    final bool? accepted,
  }) : result = result ?? (valid ? 'not_rejected' : 'rejected'),
       accepted = accepted ?? false;

  factory ClaimCheckPayload.fromJson(final Map<String, dynamic> json) =>
      _$ClaimCheckPayloadFromJson(json);

  static const generatedSchema = _$ClaimCheckPayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final String claim;
  final bool valid;
  final String result;
  final bool accepted;
  final List<String> diagnostics;
  @JsonKey(name: 'non_claims')
  final List<String> nonClaims;

  Map<String, dynamic> toJson() => _$ClaimCheckPayloadToJson(this);
}
