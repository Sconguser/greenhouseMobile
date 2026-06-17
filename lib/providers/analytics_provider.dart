import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/analytics_model.dart';
import 'http_conf.dart';
import 'http_service.dart';

part 'analytics_provider.g.dart';

// ─── Time range ───────────────────────────────────────────────────────────────

enum AnalyticsRange {
  last24h('Last 24 h', Duration(hours: 24)),
  last7d('Last 7 days', Duration(days: 7)),
  last30d('Last 30 days', Duration(days: 30));

  const AnalyticsRange(this.label, this.duration);
  final String label;
  final Duration duration;

  DateTime get from => DateTime.now().subtract(duration);
  DateTime get to => DateTime.now();
}

// ─── Entity level enum (where the parameter lives) ────────────────────────────

enum EntityLevel { greenhouse, zone, flowerpot }

// ─── Parameter history (single parameter) ────────────────────────────────────

@riverpod
Future<ParameterHistoryResponse> parameterHistory(
  ParameterHistoryRef ref, {
  required int parameterId,
  required AnalyticsRange range,
  int maxPoints = 200,
}) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/analytics/parameter/$parameterId/history',
        queryParams: {
          'from': _isoFormat(range.from),
          'to': _isoFormat(range.to),
          'maxPoints': maxPoints.toString(),
        },
      );
  final utf8Body = utf8.decode(response.bodyBytes);
  return ParameterHistoryResponse.fromJson(
      jsonDecode(utf8Body) as Map<String, dynamic>);
}

// ─── Greenhouse events ────────────────────────────────────────────────────────

@riverpod
Future<List<GreenhouseEvent>> greenhouseEvents(
  GreenhouseEventsRef ref, {
  required int greenhouseId,
  required AnalyticsRange range,
}) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/analytics/greenhouse/$greenhouseId/events',
        queryParams: {
          'from': _isoFormat(range.from),
          'to': _isoFormat(range.to),
        },
      );
  final utf8Body = utf8.decode(response.bodyBytes);
  final List<dynamic> decoded = jsonDecode(utf8Body);
  return decoded
      .map((e) => GreenhouseEvent.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ─── Device logs (serial-monitor feed) ────────────────────────────────────────

@riverpod
Future<List<DeviceLog>> deviceLogs(
  DeviceLogsRef ref, {
  required int greenhouseId,
  int limit = 200,
}) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/analytics/greenhouse/$greenhouseId/logs',
        queryParams: {'limit': limit.toString()},
      );
  final utf8Body = utf8.decode(response.bodyBytes);
  final List<dynamic> decoded = jsonDecode(utf8Body);
  return decoded
      .map((e) => DeviceLog.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ─── Greenhouse stats ─────────────────────────────────────────────────────────

@riverpod
Future<GreenhouseStats> greenhouseStats(
  GreenhouseStatsRef ref, {
  required int greenhouseId,
  required AnalyticsRange range,
}) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/analytics/greenhouse/$greenhouseId/stats',
        queryParams: {
          'from': _isoFormat(range.from),
          'to': _isoFormat(range.to),
        },
      );
  final utf8Body = utf8.decode(response.bodyBytes);
  return GreenhouseStats.fromJson(
      jsonDecode(utf8Body) as Map<String, dynamic>);
}

// ─── Analytics settings ───────────────────────────────────────────────────────

@riverpod
Future<AnalyticsSettings> analyticsSettings(AnalyticsSettingsRef ref) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/analytics/settings',
      );
  final utf8Body = utf8.decode(response.bodyBytes);
  return AnalyticsSettings.fromJson(
      jsonDecode(utf8Body) as Map<String, dynamic>);
}

@riverpod
class AnalyticsSettingsNotifier extends _$AnalyticsSettingsNotifier {
  @override
  Future<AnalyticsSettings> build() async {
    final response = await ref.read(httpServiceProvider).request(
          method: HttpMethod.get,
          endpoint: '/analytics/settings',
        );
    final utf8Body = utf8.decode(response.bodyBytes);
    return AnalyticsSettings.fromJson(
        jsonDecode(utf8Body) as Map<String, dynamic>);
  }

  Future<void> save(AnalyticsSettings settings) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.put,
            endpoint: '/analytics/settings',
            body: settings.toJson(),
          );
      final utf8Body = utf8.decode(response.bodyBytes);
      state = AsyncValue.data(
          AnalyticsSettings.fromJson(jsonDecode(utf8Body) as Map<String, dynamic>));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Formats a [DateTime] as e.g. {@code 2026-05-27T14:00:00},
/// matching Spring's @DateTimeFormat(iso = DATE_TIME).
String _isoFormat(DateTime dt) => dt.toIso8601String().substring(0, 19);