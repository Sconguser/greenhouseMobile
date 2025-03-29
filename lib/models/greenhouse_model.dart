import 'package:freezed_annotation/freezed_annotation.dart';

import 'greenhouse_status_model.dart';
import 'plant_model.dart';

part 'greenhouse_model.freezed.dart';

part 'greenhouse_model.g.dart';

@freezed
abstract class Greenhouse with _$Greenhouse {
  const Greenhouse._();
  factory Greenhouse({
    required int id,
    required String name,
    required String location,
    required String ipAddress,
    GreenhouseStatus? status,
    @Default([]) List<Plant> plants,
  }) = _Greenhouse;

  factory Greenhouse.fromJson(Map<String, dynamic> json) =>
      _$GreenhouseFromJson(json);
}
