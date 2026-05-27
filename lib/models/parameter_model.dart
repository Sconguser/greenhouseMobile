import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity_marker.dart';
import 'parameter_type.dart';

part 'parameter_model.freezed.dart';

part 'parameter_model.g.dart';

@freezed
abstract class Parameter with _$Parameter implements EntityMarker {
  const Parameter._();

  factory Parameter({
    int? id,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
    required bool mutable,
    double? currentValue,
    double? requestedValue,
    required double min,
    required double max,
    required String? unit,
    required ParameterType parameterType,
  }) = _Parameter;

  factory Parameter.fromJson(Map<String, dynamic> json) =>
      _$ParameterFromJson(json);

  @override
  String get getName => name;

  @override
  int? get getId => id;
}
