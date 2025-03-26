// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlantImpl _$$PlantImplFromJson(Map<String, dynamic> json) => _$PlantImpl(
      name: json['name'] as String,
      description: json['description'] as String,
      minTemperature: (json['minTemperature'] as num).toInt(),
      maxTemperature: (json['maxTemperature'] as num).toInt(),
      minHumidity: (json['minHumidity'] as num).toInt(),
      maxHumidity: (json['maxHumidity'] as num).toInt(),
      minSoilHumidity: (json['minSoilHumidity'] as num).toInt(),
      maxSoilHumidity: (json['maxSoilHumidity'] as num).toInt(),
      imageData: json['imageData'] as String?,
    );

Map<String, dynamic> _$$PlantImplToJson(_$PlantImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'minTemperature': instance.minTemperature,
      'maxTemperature': instance.maxTemperature,
      'minHumidity': instance.minHumidity,
      'maxHumidity': instance.maxHumidity,
      'minSoilHumidity': instance.minSoilHumidity,
      'maxSoilHumidity': instance.maxSoilHumidity,
      'imageData': instance.imageData,
    };
