//
//
import 'package:freezed_annotation/freezed_annotation.dart';
//
//
part 'plant_model.freezed.dart';
part 'plant_model.g.dart';

@freezed
class Plant with _$Plant {
  factory Plant({
    required int id,
    required String name,
    required String description,
    required String special_needs,
    required String required_temperature,
    required String required_humidity,
    String? image_url,
  }) = _Plant;
  factory Plant.fromJson(Map<String, dynamic> json) => _$PlantFromJson(json);
}
