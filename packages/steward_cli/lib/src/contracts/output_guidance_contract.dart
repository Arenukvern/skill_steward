import 'package:json_annotation/json_annotation.dart';

part 'output_guidance_contract.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  createJsonSchema: true,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
)
class OutputGuidancePayload {
  const OutputGuidancePayload({
    required this.observation,
    required this.basis,
    required this.uncertainty,
    required this.nextStep,
    required this.precondition,
    required this.verifyExpected,
    required this.returnToGoal,
    required this.expand,
    this.originalGoal,
    this.sourceRevision,
    this.nextArgv,
    this.verifyArgv,
    this.schemaVersion = 'steward.output-guidance.v1',
    this.advisory = true,
  });
  factory OutputGuidancePayload.fromJson(final Map<String, dynamic> json) =>
      _$OutputGuidancePayloadFromJson(json);
  static const generatedSchema = _$OutputGuidancePayloadJsonSchema;
  final String schemaVersion;
  final bool advisory;
  final String? originalGoal;
  final String? sourceRevision;
  final String observation;
  final List<String> basis;
  final List<String> uncertainty;
  final String nextStep;
  final List<String>? nextArgv;
  final String precondition;
  final List<String>? verifyArgv;
  final String verifyExpected;
  final String returnToGoal;
  final List<String> expand;
  Map<String, dynamic> toJson() => _$OutputGuidancePayloadToJson(this);
}
