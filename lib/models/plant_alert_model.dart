import 'package:freezed_annotation/freezed_annotation.dart';

import 'requirement_kind.dart';

part 'plant_alert_model.freezed.dart';
part 'plant_alert_model.g.dart';

/// A plant-health breach reported by the server. Mirrors `PlantAlertDTO`.
@freezed
abstract class PlantAlert with _$PlantAlert {
  const PlantAlert._();

  const factory PlantAlert({
    required int id,
    required int greenhouseId,
    String? greenhouseName,
    int? flowerpotId,
    String? flowerpotName,
    int? plantId,
    String? plantName,
    String? requirementName,
    String? parameterName,
    String? unit,
    @Default(RequirementKind.threshold) RequirementKind kind,
    double? lowerThreshold,
    double? upperThreshold,
    double? lastValue,
    required String status, // "PENDING" | "ACTIVE" | "RESOLVED"
    String? message,
    DateTime? firstDetectedAt,
    DateTime? raisedAt,
    DateTime? resolvedAt,
    DateTime? lastSeenAt,
  }) = _PlantAlert;

  factory PlantAlert.fromJson(Map<String, dynamic> json) =>
      _$PlantAlertFromJson(json);

  bool get isActive => status == 'ACTIVE';
  bool get isResolved => status == 'RESOLVED';
}
