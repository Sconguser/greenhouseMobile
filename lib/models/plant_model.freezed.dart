// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plant_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Plant _$PlantFromJson(Map<String, dynamic> json) {
  return _Plant.fromJson(json);
}

/// @nodoc
mixin _$Plant {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get special_needs => throw _privateConstructorUsedError;
  String get required_temperature => throw _privateConstructorUsedError;
  String get required_humidity => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlantCopyWith<Plant> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlantCopyWith<$Res> {
  factory $PlantCopyWith(Plant value, $Res Function(Plant) then) =
      _$PlantCopyWithImpl<$Res, Plant>;
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      String special_needs,
      String required_temperature,
      String required_humidity,
      String? image_url});
}

/// @nodoc
class _$PlantCopyWithImpl<$Res, $Val extends Plant>
    implements $PlantCopyWith<$Res> {
  _$PlantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? special_needs = null,
    Object? required_temperature = null,
    Object? required_humidity = null,
    Object? image_url = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      special_needs: null == special_needs
          ? _value.special_needs
          : special_needs // ignore: cast_nullable_to_non_nullable
              as String,
      required_temperature: null == required_temperature
          ? _value.required_temperature
          : required_temperature // ignore: cast_nullable_to_non_nullable
              as String,
      required_humidity: null == required_humidity
          ? _value.required_humidity
          : required_humidity // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlantImplCopyWith<$Res> implements $PlantCopyWith<$Res> {
  factory _$$PlantImplCopyWith(
          _$PlantImpl value, $Res Function(_$PlantImpl) then) =
      __$$PlantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      String special_needs,
      String required_temperature,
      String required_humidity,
      String? image_url});
}

/// @nodoc
class __$$PlantImplCopyWithImpl<$Res>
    extends _$PlantCopyWithImpl<$Res, _$PlantImpl>
    implements _$$PlantImplCopyWith<$Res> {
  __$$PlantImplCopyWithImpl(
      _$PlantImpl _value, $Res Function(_$PlantImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? special_needs = null,
    Object? required_temperature = null,
    Object? required_humidity = null,
    Object? image_url = freezed,
  }) {
    return _then(_$PlantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      special_needs: null == special_needs
          ? _value.special_needs
          : special_needs // ignore: cast_nullable_to_non_nullable
              as String,
      required_temperature: null == required_temperature
          ? _value.required_temperature
          : required_temperature // ignore: cast_nullable_to_non_nullable
              as String,
      required_humidity: null == required_humidity
          ? _value.required_humidity
          : required_humidity // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlantImpl implements _Plant {
  _$PlantImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.special_needs,
      required this.required_temperature,
      required this.required_humidity,
      this.image_url});

  factory _$PlantImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlantImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String special_needs;
  @override
  final String required_temperature;
  @override
  final String required_humidity;
  @override
  final String? image_url;

  @override
  String toString() {
    return 'Plant(id: $id, name: $name, description: $description, special_needs: $special_needs, required_temperature: $required_temperature, required_humidity: $required_humidity, image_url: $image_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.special_needs, special_needs) ||
                other.special_needs == special_needs) &&
            (identical(other.required_temperature, required_temperature) ||
                other.required_temperature == required_temperature) &&
            (identical(other.required_humidity, required_humidity) ||
                other.required_humidity == required_humidity) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      special_needs, required_temperature, required_humidity, image_url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlantImplCopyWith<_$PlantImpl> get copyWith =>
      __$$PlantImplCopyWithImpl<_$PlantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlantImplToJson(
      this,
    );
  }
}

abstract class _Plant implements Plant {
  factory _Plant(
      {required final int id,
      required final String name,
      required final String description,
      required final String special_needs,
      required final String required_temperature,
      required final String required_humidity,
      final String? image_url}) = _$PlantImpl;

  factory _Plant.fromJson(Map<String, dynamic> json) = _$PlantImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get special_needs;
  @override
  String get required_temperature;
  @override
  String get required_humidity;
  @override
  String? get image_url;
  @override
  @JsonKey(ignore: true)
  _$$PlantImplCopyWith<_$PlantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
