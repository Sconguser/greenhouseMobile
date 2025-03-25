import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:maker_greenhouse/providers/http_service.dart';
import 'package:maker_greenhouse/providers/secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user_model.dart';
import 'http_conf.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  static const tokenKey = "jwt_token";

  @override
  Future<User?> build() async {
    // return _loadPersistedToken();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      Response response = await ref.read(httpServiceProvider).request(
            method: HttpMethod.post,
            endpoint: 'auth/login',
            body: {'username': username, 'password': password},
            requireAuth: false,
          );
      String? token = response.headers['authorization'];
      if (token == null) {
        throw Exception("Auth returned null token, contact support");
      } else {
        ref.read(secureStorageProvider).write(key: tokenKey, value: token);
        state = AsyncValue.data(User.fromJson(jsonDecode(response.body)));
      }
    } catch (e) {
      ///TODO: exception handling
      debugPrint("WSZEDLEM TUTAJ");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
