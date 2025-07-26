
import 'package:freezed_annotation/freezed_annotation.dart';

import 'parameter_type.dart';

part 'parameter_model.freezed.dart';

part 'parameter_model.g.dart';

@freezed
abstract class Parameter with _$Parameter {
  const Parameter._();

  factory Parameter({
    int? id,
    required String name,
    required bool mutable,
    required double currentValue,
    required double requestedValue,
    required double min,
    required double max,
    required String unit,
    required ParameterType type,
  }) = _Parameter;

  factory Parameter.fromJson(Map<String, dynamic> json) =>
      _$ParameterFromJson(json);
}
