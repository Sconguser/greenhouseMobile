import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:maker_greenhouse/models/has_parametrized_children.dart';
import 'package:maker_greenhouse/models/parameter_model.dart';
import 'package:maker_greenhouse/models/has_parameters.dart';
import 'package:maker_greenhouse/models/zone_model.dart';
import 'package:maker_greenhouse/models/greenhouse_status_model.dart';

part 'greenhouse_model.freezed.dart';

part 'greenhouse_model.g.dart';

@freezed
abstract class Greenhouse
    with _$Greenhouse
    implements HasParametrizedChildren, HasParameters {
  const Greenhouse._();

  factory Greenhouse({
    int? id,
    required String name,
    required String location,
    required String ipAddress,
    @Default(Status.NOT_RESPONSIVE) Status status,
    DateTime? lastUpdate,
    DateTime? lastPushed,
    @Default(true) bool deviceConfigSynced,
    @Default(true) bool mappingConfigSynced,
    @Default(true) bool modelSynced,
    @Default([]) List<Zone> zones,
    @Default([]) List<Parameter> parameters,
  }) = _Greenhouse;

  factory Greenhouse.fromJson(Map<String, dynamic> json) =>
      _$GreenhouseFromJson(json);

  @override
  List<Parameter> get parameterList => parameters;

  @override
  List<HasParameters> get parametrizedChildren => zones;

  @override
  String get getName => name;

  @override
  int? get getId => id;
}
