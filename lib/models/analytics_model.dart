import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_model.freezed.dart';
part 'analytics_model.g.dart';

// ─── Greenhouse event (BOOT / CRASH) ──────────────────────────────────────────

@freezed
abstract class GreenhouseEvent with _$GreenhouseEvent {
  const factory GreenhouseEvent({
    required int id,
    required int greenhouseId,
    required String eventType, // "BOOT" | "CRASH"
    required DateTime occurredAt,
    String? details,
  }) = _GreenhouseEvent;

  factory GreenhouseEvent.fromJson(Map<String, dynamic> json) =>
      _$GreenhouseEventFromJson(json);
}

// ─── Device log line (serial-monitor feed) ────────────────────────────────────

@freezed
abstract class DeviceLog with _$DeviceLog {
  const factory DeviceLog({
    required int id,
    required String source, // "DEVICE" | "EVENT"
    required String level, // "INFO" | "WARN" | "ERROR"
    String? code,
    String? message,
    int? freeHeap,
    int? deviceUptime,
    required DateTime timestamp,
  }) = _DeviceLog;

  factory DeviceLog.fromJson(Map<String, dynamic> json) =>
      _$DeviceLogFromJson(json);
}

// ─── Aggregate stats ──────────────────────────────────────────────────────────

@freezed
abstract class GreenhouseStats with _$GreenhouseStats {
  const factory GreenhouseStats({
    required int greenhouseId,
    required int bootCount,
    required int crashCount,
    required DateTime from,
    required DateTime to,
  }) = _GreenhouseStats;

  factory GreenhouseStats.fromJson(Map<String, dynamic> json) =>
      _$GreenhouseStatsFromJson(json);
}

// ─── Parameter history ────────────────────────────────────────────────────────

@freezed
abstract class ParameterHistoryPoint with _$ParameterHistoryPoint {
  const factory ParameterHistoryPoint({
    required DateTime timestamp,
    required double value,
  }) = _ParameterHistoryPoint;

  factory ParameterHistoryPoint.fromJson(Map<String, dynamic> json) =>
      _$ParameterHistoryPointFromJson(json);
}

@freezed
abstract class ParameterHistoryResponse with _$ParameterHistoryResponse {
  const factory ParameterHistoryResponse({
    required int parameterId,
    required String parameterName,
    String? unit,
    @Default([]) List<ParameterHistoryPoint> points,
  }) = _ParameterHistoryResponse;

  factory ParameterHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$ParameterHistoryResponseFromJson(json);
}

// ─── Analytics settings ────────────────────────────────────────────────────────

@freezed
abstract class AnalyticsSettings with _$AnalyticsSettings {
  const factory AnalyticsSettings({
    @Default(true) bool analyticsEnabled,
    @Default(90) int historyRetentionDays,
    @Default(365) int eventsRetentionDays,
    @Default(7) int logsRetentionDays,
    @Default(24) int cleanupIntervalHours,
    DateTime? lastCleanup,
  }) = _AnalyticsSettings;

  factory AnalyticsSettings.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSettingsFromJson(json);
}