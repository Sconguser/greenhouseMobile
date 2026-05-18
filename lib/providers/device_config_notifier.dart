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

  Future<void> saveDeviceConfig(List<DeviceConfig> configs) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/$greenhouseId/config/devices',
            body: configs.map((c) => c.toJson()).toList(),
          );
      state = AsyncValue.data(configs);
      unawaited(ref.read(greenhouseNotifierProvider.notifier).silentRefresh());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}