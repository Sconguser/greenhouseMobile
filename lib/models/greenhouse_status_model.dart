import 'package:freezed_annotation/freezed_annotation.dart';

part 'greenhouse_status_model.freezed.dart';

part 'greenhouse_status_model.g.dart';

enum Status { ON, OFF, NOT_RESPONSIVE }

@freezed
class GreenhouseStatus with _$GreenhouseStatus {
  factory GreenhouseStatus({
    required double temperature,
    required double humidity,
    required double soilHumidity,
    required Status status,
  }) = _GreenhouseStatus;

  factory GreenhouseStatus.fromJson(Map<String, dynamic> json) =>
      _$GreenhouseStatusFromJson(json);
}
