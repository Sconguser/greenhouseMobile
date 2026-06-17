import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_config_model.freezed.dart';
part 'device_config_model.g.dart';

@freezed
abstract class DeviceConfig with _$DeviceConfig {
  factory DeviceConfig({
    int? id, // server-assigned stable id; null until first save
    required String name,
    required String driver, // "digital", "dht22", "muxAnalog"
    required String type,   // "value", "toggle"
    required int pin,
  }) = _DeviceConfig;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigFromJson(json);
}