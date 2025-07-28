//
//
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:maker_greenhouse/models/has_requirements.dart';
import 'package:maker_greenhouse/models/requirement_model.dart';

//
//
part 'plant_model.freezed.dart';

part 'plant_model.g.dart';

@freezed
abstract class Plant with _$Plant implements HasRequirements {
  const Plant._();

  factory Plant({
    int? id,
    required String name,
    required String description,
    String? imageData,
    @Default([]) List<Requirement> requirements,
  }) = _Plant;

  factory Plant.fromJson(Map<String, dynamic> json) => _$PlantFromJson(json);

  @override
  List<Requirement> get requirementList => requirements;

  @override
  String get getName => name;

  @override
  int? get getId => id;
}
