import 'package:maker_greenhouse/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_conf.g.dart';

@riverpod
class HttpConfig extends _$HttpConfig {
  late final PreferencesService _preferencesService;

  @override
  Future<HttpConfigModel> build() async {
    _preferencesService = ref.read(preferencesServiceProvider);
    ref.keepAlive();
    return await _getHttpConfigFromPreferences();
  }

  Future<HttpConfigModel> _getHttpConfigFromPreferences() async {
    return await _preferencesService.getHttpConfig();
  }

  Future<void> changeConfig(HttpConfigModel httpConfig) async {
    state = const AsyncValue.loading();
    await _preferencesService.setHttpConfig(httpConfig);
    state = AsyncValue.data(httpConfig);
  }
}

class HttpConfigModel {
  final String baseUrl;
  final Duration timeout;
  final bool useHttps;

  HttpConfigModel({
    required this.baseUrl,
    required this.timeout,
    required this.useHttps,
  });
}

enum HttpMethod { get, post, put, patch, delete }

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'HTTP $statusCode: $message';
}
