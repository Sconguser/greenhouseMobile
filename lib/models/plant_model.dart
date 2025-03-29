//
//
import 'package:freezed_annotation/freezed_annotation.dart';

//
//
part 'plant_model.freezed.dart';

part 'plant_model.g.dart';

@freezed
abstract class Plant with _$Plant {
  const Plant._();
  factory Plant({
    required String name,
    required String description,
    required int minTemperature,
    required int maxTemperature,
    required int minHumidity,
    required int maxHumidity,
    required int minSoilHumidity,
    required int maxSoilHumidity,
    String? imageData,
  }) = _Plant;

  factory Plant.fromJson(Map<String, dynamic> json) => _$PlantFromJson(json);
}
