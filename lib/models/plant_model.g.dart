// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlantImpl _$$PlantImplFromJson(Map<String, dynamic> json) => _$PlantImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      special_needs: json['special_needs'] as String,
      required_temperature: json['required_temperature'] as String,
      required_humidity: json['required_humidity'] as String,
      image_url: json['image_url'] as String?,
    );

Map<String, dynamic> _$$PlantImplToJson(_$PlantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'special_needs': instance.special_needs,
      'required_temperature': instance.required_temperature,
      'required_humidity': instance.required_humidity,
      'image_url': instance.image_url,
    };
