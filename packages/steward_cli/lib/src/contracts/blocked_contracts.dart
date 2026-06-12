import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_contracts.freezed.dart';
part 'blocked_contracts.g.dart';

@freezed
sealed class BlockedRouteDecision with _$BlockedRouteDecision {
  const factory BlockedRouteDecision({
    required final String blockedBy,
    required final String artifactRoute,
    required final List<String> nextActions,
  }) = _BlockedRouteDecision;
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class BlockedExplanationPayload {
  const BlockedExplanationPayload({
    required this.root,
    required this.input,
    required this.blockedBy,
    required this.artifactRoute,
    required this.nextActions,
    required this.nonClaims,
    this.schemaVersion = 'steward.blocked.explain.v1',
  });

  factory BlockedExplanationPayload.fromJson(final Map<String, dynamic> json) =>
      _$BlockedExplanationPayloadFromJson(json);

  static const generatedSchema = _$BlockedExplanationPayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final String root;
  final String input;
  @JsonKey(name: 'blocked_by')
  final String blockedBy;
  @JsonKey(name: 'artifact_route')
  final String artifactRoute;
  @JsonKey(name: 'next_actions')
  final List<String> nextActions;
  @JsonKey(name: 'non_claims')
  final List<String> nonClaims;

  Map<String, dynamic> toJson() => _$BlockedExplanationPayloadToJson(this);
}
