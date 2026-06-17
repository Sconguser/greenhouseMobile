import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/plant_alert_model.dart';
import 'http_conf.dart';
import 'http_service.dart';

part 'plant_alert_provider.g.dart';

/// Plant-health alerts for a greenhouse. [includeResolved] also returns recent
/// resolved breaches (history); otherwise only currently-active ones.
@riverpod
Future<List<PlantAlert>> plantAlerts(
  PlantAlertsRef ref, {
  required int greenhouseId,
  bool includeResolved = false,
}) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/plants/alerts/greenhouse/$greenhouseId',
        queryParams: {'includeResolved': includeResolved.toString()},
      );
  final utf8Body = utf8.decode(response.bodyBytes);
  final List<dynamic> decoded = jsonDecode(utf8Body);
  return decoded
      .map((e) => PlantAlert.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Active-alert count for a greenhouse (cheap badge query).
@riverpod
Future<int> plantAlertCount(
  PlantAlertCountRef ref, {
  required int greenhouseId,
}) async {
  final response = await ref.read(httpServiceProvider).request(
        method: HttpMethod.get,
        endpoint: '/plants/alerts/greenhouse/$greenhouseId/count',
      );
  return int.tryParse(utf8.decode(response.bodyBytes).trim()) ?? 0;
}

/// Dismisses (deletes) a single alert, then invalidates the lists for its
/// greenhouse so the UI refreshes.
@riverpod
Future<void> dismissPlantAlert(
  DismissPlantAlertRef ref, {
  required int alertId,
  required int greenhouseId,
}) async {
  await ref.read(httpServiceProvider).request(
        method: HttpMethod.delete,
        endpoint: '/plants/alerts/$alertId',
      );
  ref.invalidate(plantAlertsProvider(greenhouseId: greenhouseId));
  ref.invalidate(
      plantAlertsProvider(greenhouseId: greenhouseId, includeResolved: true));
  ref.invalidate(plantAlertCountProvider(greenhouseId: greenhouseId));
}
