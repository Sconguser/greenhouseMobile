import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:maker_greenhouse/models/entity_marker.dart';

import 'parameter_type.dart';
import 'requirement_kind.dart';

part 'requirement_model.freezed.dart';

part 'requirement_model.g.dart';

@freezed
abstract class Requirement with _$Requirement implements EntityMarker {
  const Requirement._();

  factory Requirement({
    int? id,
    required String name,
    required double lowerThreshold,
    required double upperThreshold,
    required String unit,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'type') required ParameterType parameterType,
    @Default(RequirementKind.threshold) RequirementKind kind,
  }) = _Requirement;

  factory Requirement.fromJson(Map<String, dynamic> json) =>
      _$RequirementFromJson(json);

  @override
  int? get getId => id;

  @override
  String get getName => name;
}
