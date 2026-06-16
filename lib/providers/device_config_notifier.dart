import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/device_config_model.dart';
import 'greenhouse_notifier.dart';
import 'http_conf.dart';
import 'http_service.dart';

part 'device_config_notifier.g.dart';

@riverpod
class DeviceConfigNotifier extends _$DeviceConfigNotifier {
  @override
  Future<List<DeviceConfig>> build(int greenhouseId) async {
    return _load();
  }

  Future<List<DeviceConfig>> _load() async {
    final response = await ref.read(httpServiceProvider).request(
          method: HttpMethod.get,
          endpoint: '/greenhouse/$greenhouseId/config/devices',
        );
    final utf8Body = utf8.decode(response.bodyBytes);
    final List<dynamic> decoded = jsonDecode(utf8Body);
    return decoded
        .map((e) => DeviceConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Saves the devices and adopts the server's response, which carries the
  /// server-assigned ids. Returns the id-stamped list so callers can update
  /// their local copy and immediately reference devices by id (e.g. when
  /// building mappings) — the app never holds an id-less device state.
  Future<List<DeviceConfig>> saveDeviceConfig(List<DeviceConfig> configs) async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/$greenhouseId/config/devices',
            body: configs.map((c) => c.toJson()).toList(),
          );
      final utf8Body = utf8.decode(response.bodyBytes);
      final List<dynamic> decoded = jsonDecode(utf8Body);
      final saved = decoded
          .map((e) => DeviceConfig.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(saved);
      unawaited(ref.read(greenhouseNotifierProvider.notifier).silentRefresh());
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}