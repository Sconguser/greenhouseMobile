
import 'package:freezed_annotation/freezed_annotation.dart';

import 'parameter_type.dart';

part 'requirement_model.freezed.dart';
part 'requirement_model.g.dart';


@freezed
abstract class Requirement with _$Requirement{
  const Requirement._();

  factory Requirement({
    int? id,
    required String name,
    required double lowerThreshold,
    required double upperThreshold,
    required String unit,
    required ParameterType type,
}) = _Requirement;
  factory Requirement.fromJson(Map<String, dynamic>json)=>
      _$RequirementFromJson(json);
}