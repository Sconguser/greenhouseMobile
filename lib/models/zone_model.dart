import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:maker_greenhouse/models/has_parameters.dart';
import 'package:maker_greenhouse/models/has_parametrized_children.dart';
import 'package:maker_greenhouse/models/parameter_model.dart';

import 'flowerpot_model.dart';

part 'zone_model.freezed.dart';

part 'zone_model.g.dart';

@freezed
abstract class Zone
    with _$Zone
    implements HasParameters, HasParametrizedChildren {
  const Zone._();

  factory Zone({
    int? id,
    required String name,
    DateTime? createdAt,
    @Default([]) List<Flowerpot> flowerpots,
    @Default([]) List<Parameter> parameters,
  }) = _Zone;

  factory Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);

  @override
  List<Parameter> get parameterList => parameters;

  @override
  List<HasParameters> get parametrizedChildren => flowerpots;

  @override
  String get getName => name;

  @override
  int? get getId => id;
}
