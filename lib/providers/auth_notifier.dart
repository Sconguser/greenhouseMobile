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
  @override
  Future<User?> build() async {
    if (await ref
            .read(secureStorageProvider.notifier)
            .read(KEYS.jwtToken.name) !=
        null) {
      return _autoLogin();
    }
    return null;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      ref.read(secureStorageProvider).delete(key: KEYS.jwtToken.name);
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
        ref
            .read(secureStorageProvider)
            .write(key: KEYS.jwtToken.name, value: token);
        state = AsyncValue.data(User.fromJson(jsonDecode(response.body)));
      }
    } catch (e) {
      ///TODO: exception handling
      debugPrint("Error with signin");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signUp(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      ref.read(secureStorageProvider).delete(key: KEYS.jwtToken.name);
      await ref.read(httpServiceProvider).request(
          method: HttpMethod.post,
          endpoint: '/auth/register',
          body: {"username": username, "password": password},
          requireAuth: false);
      ref.invalidateSelf();
    } catch (e) {
      ///TODO: exception handling when exception is nothing serious
      debugPrint("Error with signup");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<User?> _autoLogin() async {
    state = const AsyncValue.loading();
    try {
      Response response = await ref.read(httpServiceProvider).request(
          method: HttpMethod.get, endpoint: 'auth/verify', requireAuth: true);
      return User.fromJson(jsonDecode(response.body));
    } catch (e) {
      ref.read(secureStorageProvider).delete(key: KEYS.jwtToken.name);
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
}
