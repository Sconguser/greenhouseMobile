import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/mapping_config_model.dart';
import 'http_conf.dart';
import 'http_service.dart';

part 'mapping_config_notifier.g.dart';

@riverpod
class MappingConfigNotifier extends _$MappingConfigNotifier {
  @override
  Future<List<MappingConfig>> build(int greenhouseId) async {
    return _load();
  }

  Future<List<MappingConfig>> _load() async {
    final response = await ref.read(httpServiceProvider).request(
          method: HttpMethod.get,
          endpoint: '/greenhouse/$greenhouseId/config/mapping',
        );
    final utf8Body = utf8.decode(response.bodyBytes);
    final List<dynamic> decoded = jsonDecode(utf8Body);
    return decoded
        .map((e) => MappingConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMappingConfig(List<MappingConfig> mappings) async {
    state = AsyncValue.loading();
    try {
      await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: '/greenhouse/$greenhouseId/config/mapping',
            body: mappings.map((m) => m.toJson()).toList(),
          );
      state = AsyncValue.data(mappings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}