import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_conf.g.dart';

@riverpod
class HttpConfig extends _$HttpConfig {
  @override
  HttpConfigModel build() => HttpConfigModel(
        baseUrl: '192.168.0.194:8080',
        timeout: const Duration(seconds: 20),
        useHttps: false,
      );
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
