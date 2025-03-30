import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

enum KEYS { jwtToken, fcmToken }

@riverpod
class SecureStorage extends _$SecureStorage {
  @override
  FlutterSecureStorage build() => const FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    await state.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await state.read(key: key);
  }

  Future<void> delete(String key) async {
    await state.delete(key: key);
  }
}
