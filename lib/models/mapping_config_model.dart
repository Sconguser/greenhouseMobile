import 'package:freezed_annotation/freezed_annotation.dart';

part 'mapping_config_model.freezed.dart';
part 'mapping_config_model.g.dart';

@freezed
abstract class MappingConfig with _$MappingConfig {
  factory MappingConfig({
    required String scope,        // "greenhouse", "zone", "flowerpot"
    int? zoneId,
    int? flowerpotId,
    required String paramName,

    // Read (sensor) configuration — references a device by its server-assigned
    // id; driver/pin live on the device inventory, the board resolves them.
    int? readDeviceId,
    int? muxChannel,
    @Default([]) List<int> muxSelPins,

    // Write (actuator) configuration — references a device by its id.
    int? writeDeviceId,
    String? direction,            // "increase", "decrease"
    double? hysteresis,
    bool? activeLow,
    int? minOnMs,
    int? minOffMs,
    String? outputMode,           // "binary"

    // Analog value scaling
    double? mapInMin,
    double? mapInMax,
    double? mapOutMin,
    double? mapOutMax,
  }) = _MappingConfig;

  factory MappingConfig.fromJson(Map<String, dynamic> json) =>
      _$MappingConfigFromJson(json);
}