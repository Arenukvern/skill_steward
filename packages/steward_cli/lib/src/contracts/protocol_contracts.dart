import 'package:json_annotation/json_annotation.dart';

part 'protocol_contracts.g.dart';

@JsonEnum(alwaysCreate: true)
enum StewardMode {
  @JsonValue('tool-execution')
  toolExecution,
  @JsonValue('steward-presence')
  stewardPresence,
  @JsonValue('delegation')
  delegation,
  @JsonValue('sub-steward-lens')
  subStewardLens,
}

@JsonEnum(alwaysCreate: true)
enum StewardStatus {
  @JsonValue('stewardship_protocol')
  stewardshipProtocol,
  @JsonValue('steward_presence')
  stewardPresence,
  @JsonValue('proven_repo_steward')
  provenRepoSteward,
  @JsonValue('sub_steward')
  subSteward,
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  includeIfNull: false,
)
class ModeEventContract {
  const ModeEventContract({
    required this.id,
    required this.createdAt,
    required this.repo,
    required this.mode,
    required this.status,
    required this.intent,
    required this.evidenceBar,
    required this.nonClaims,
    this.schema = 'steward/mode-event/v1',
    this.delegatedSurface,
    this.boundarySignals,
    this.selfModelPointer,
  });

  factory ModeEventContract.fromJson(final Map<String, dynamic> json) =>
      _$ModeEventContractFromJson(json);

  static const generatedSchema = _$ModeEventContractJsonSchema;

  @JsonKey(required: true)
  final String schema;
  final String id;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final String repo;
  final StewardMode mode;
  final StewardStatus status;
  final String intent;
  @JsonKey(name: 'delegated_surface')
  final String? delegatedSurface;
  @JsonKey(name: 'evidence_bar')
  final String evidenceBar;
  @JsonKey(name: 'boundary_signals')
  final List<String>? boundarySignals;
  @JsonKey(name: 'self_model_pointer')
  final String? selfModelPointer;
  @JsonKey(name: 'non_claims')
  final List<String> nonClaims;

  Map<String, dynamic> toJson() => _$ModeEventContractToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
  includeIfNull: false,
)
class SelfModelContract {
  const SelfModelContract({
    required this.stewardId,
    required this.repo,
    required this.status,
    required this.identityRole,
    required this.boundaryAwareness,
    required this.openQuestions,
    required this.valuesInAction,
    required this.reflectiveState,
    required this.triggerEventId,
    required this.consentBasis,
    required this.visibility,
    required this.retention,
    required this.redactionPolicy,
    required this.nonClaims,
    this.schema = 'steward/self-model/v1',
    this.validation,
  });

  factory SelfModelContract.fromJson(final Map<String, dynamic> json) =>
      _$SelfModelContractFromJson(json);

  static const generatedSchema = _$SelfModelContractJsonSchema;

  @JsonKey(required: true)
  final String schema;
  @JsonKey(name: 'steward_id')
  final String stewardId;
  final String repo;
  final StewardStatus status;
  @JsonKey(name: 'identity_role')
  final String identityRole;
  @JsonKey(name: 'boundary_awareness')
  final List<String> boundaryAwareness;
  @JsonKey(name: 'open_questions')
  final List<String> openQuestions;
  @JsonKey(name: 'values_in_action')
  final List<String> valuesInAction;
  @JsonKey(name: 'reflective_state')
  final String reflectiveState;
  @JsonKey(name: 'trigger_event_id')
  final String triggerEventId;
  @JsonKey(name: 'consent_basis')
  final String consentBasis;
  final String visibility;
  final String retention;
  @JsonKey(name: 'redaction_policy')
  final String redactionPolicy;
  @JsonKey(name: 'non_claims')
  final List<String> nonClaims;
  final SelfModelValidationContract? validation;

  Map<String, dynamic> toJson() => _$SelfModelContractToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
class SelfModelValidationContract {
  const SelfModelValidationContract({
    required this.tasks,
    required this.comparison,
    required this.outcome,
    required this.falsifier,
    required this.reviewer,
    required this.updatedAt,
    required this.nonClaims,
  });

  factory SelfModelValidationContract.fromJson(
    final Map<String, dynamic> json,
  ) => _$SelfModelValidationContractFromJson(json);

  final List<SelfModelValidationTaskContract> tasks;
  final SelfModelComparisonContract comparison;
  final String outcome;
  final String falsifier;
  final String reviewer;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'non_claims')
  final List<String> nonClaims;

  Map<String, dynamic> toJson() => _$SelfModelValidationContractToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class SelfModelValidationTaskContract {
  const SelfModelValidationTaskContract({
    required this.id,
    required this.heldOut,
    required this.evidence,
    required this.outcome,
  });

  factory SelfModelValidationTaskContract.fromJson(
    final Map<String, dynamic> json,
  ) => _$SelfModelValidationTaskContractFromJson(json);

  final String id;
  @JsonKey(name: 'held_out')
  final bool heldOut;
  final String evidence;
  final String outcome;

  Map<String, dynamic> toJson() =>
      _$SelfModelValidationTaskContractToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
)
class SelfModelComparisonContract {
  const SelfModelComparisonContract({
    required this.withContinuityResult,
    required this.withoutContinuityResult,
  });

  factory SelfModelComparisonContract.fromJson(
    final Map<String, dynamic> json,
  ) => _$SelfModelComparisonContractFromJson(json);

  @JsonKey(name: 'with_continuity_result')
  final String withContinuityResult;
  @JsonKey(name: 'without_continuity_result')
  final String withoutContinuityResult;

  Map<String, dynamic> toJson() => _$SelfModelComparisonContractToJson(this);
}

@JsonSerializable(
  checked: true,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
class ProtocolValidatePayload {
  const ProtocolValidatePayload({
    required this.root,
    required this.valid,
    required this.diagnostics,
    required this.files,
    this.schemaVersion = 'steward.protocol.validate.v1',
  });

  factory ProtocolValidatePayload.fromJson(final Map<String, dynamic> json) =>
      _$ProtocolValidatePayloadFromJson(json);

  static const generatedSchema = _$ProtocolValidatePayloadJsonSchema;

  @JsonKey(name: 'schema_version', required: true)
  final String schemaVersion;
  final String root;
  final bool valid;
  final List<String> diagnostics;
  final Map<String, dynamic> files;

  Map<String, dynamic> toJson() => _$ProtocolValidatePayloadToJson(this);
}
