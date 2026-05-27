import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:maker_greenhouse/providers/secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'http_conf.dart';

part 'http_service.g.dart';

///TODO: refactor
@riverpod
HttpService httpService(Ref ref) => HttpService(ref);

class HttpService {
  final Ref _ref;

  HttpService(this._ref);

  Future<http.Response> request<T>({
    required HttpMethod method,
    required String endpoint,
    Object? body,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
  }) async {
    // Each request gets its own client so that parallel requests don't share
    // state and closing one doesn't kill the others.
    final client = http.Client();
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await _buildHeaders(requireAuth);
      final config = _ref.read(httpConfigProvider);

      final response = await _executeRequest(
          client: client,
          method: method,
          uri: uri,
          headers: headers,
          body: body,
          timeout: config.value?.timeout ?? const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('HTTP Error: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final config = _ref.read(httpConfigProvider);
    final baseUrl = config.value?.baseUrl ?? "1.1.1.1:8080";
    if (config.value?.useHttps ?? false) {
      return Uri.https(baseUrl, endpoint, queryParams);
    } else {
      return Uri.http(baseUrl, endpoint, queryParams);
    }
  }

  Future<Map<String, String>> _buildHeaders(bool requireAuth) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      String? token = await _ref
          .read(secureStorageProvider.notifier)
          .read(KEYS.jwtToken.name);
      if (token == null) {
        throw Exception("Authorization token was not present");
      }
      headers['Authorization'] = token;
    }

    return headers;
  }

  Future<http.Response> _executeRequest({
    required http.Client client,
    required HttpMethod method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    Duration timeout = const Duration(seconds: 30),
  }) {
    final bodyJson = body != null ? jsonEncode(body) : null;

    switch (method) {
      case HttpMethod.get:
        return client.get(uri, headers: headers).timeout(timeout);
      case HttpMethod.post:
        return client
            .post(uri, headers: headers, body: bodyJson)
            .timeout(timeout);
      case HttpMethod.put:
        return client
            .put(uri, headers: headers, body: bodyJson)
            .timeout(timeout);
      case HttpMethod.patch:
        return client
            .patch(uri, headers: headers, body: bodyJson)
            .timeout(timeout);
      case HttpMethod.delete:
        return client.delete(uri, headers: headers).timeout(timeout);
    }
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw HttpException(
        statusCode: response.statusCode,
        message: jsonDecode(response.body)['message'] ?? 'Unknown error',
      );
    }
  }
}
