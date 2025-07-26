import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:maker_greenhouse/models/has_parameters.dart';
import 'package:maker_greenhouse/models/has_plants.dart';
import 'package:maker_greenhouse/models/parameter_model.dart';
import 'package:maker_greenhouse/models/plant_model.dart';

part 'flowerpot_model.freezed.dart';

part 'flowerpot_model.g.dart';

@freezed
abstract class Flowerpot with _$Flowerpot implements HasPlants, HasParameters {
  const Flowerpot._();

  factory Flowerpot({
    int? id,
    required String name,
    @Default([]) List<Plant> plants,
    @Default([]) List<Parameter> parameters,
  }) = _Flowerpot;

  factory Flowerpot.fromJson(Map<String, dynamic> json) =>
      _$FlowerpotFromJson(json);

  @override
  List<Parameter> get parameterList => parameters;

  @override
  List<Plant> get plantList => plants;

  @override
  String get getName => name;
}
