import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'http_conf.dart';

part 'http_service.g.dart';

@riverpod
HttpService httpService(HttpServiceRef ref) => HttpService(ref);

class HttpService {
  final Ref _ref;
  final http.Client _client;

  HttpService(this._ref) : _client = http.Client();

  Future<http.Response> request<T>({
    required HttpMethod method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);

      final headers = await _buildHeaders(requireAuth);
      final config = _ref.read(httpConfigProvider);

      final response = await _executeRequest(
          method: method,
          uri: uri,
          headers: headers,
          body: body,
          timeout: config.timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('HTTP Error: $e');
      rethrow;
    } finally {
      _client.close();
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final config = _ref.read(httpConfigProvider);
    final baseUrl = config.baseUrl;
    if (config.useHttps) {
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
      // final token = await _ref.read(authProvider.future);
      String token = "aa";
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> _executeRequest({
    required HttpMethod method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) {
    final bodyJson = body != null ? jsonEncode(body) : null;

    switch (method) {
      case HttpMethod.get:
        return _client.get(uri, headers: headers).timeout(timeout);
      case HttpMethod.post:
        return _client
            .post(uri, headers: headers, body: bodyJson)
            .timeout(timeout);
      case HttpMethod.put:
        return _client
            .put(uri, headers: headers, body: bodyJson)
            .timeout(timeout);
      case HttpMethod.patch:
        return _client
            .patch(uri, headers: headers, body: bodyJson)
            .timeout(timeout);
      case HttpMethod.delete:
        return _client.delete(uri, headers: headers).timeout(timeout);
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
