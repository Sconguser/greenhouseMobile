import 'package:maker_greenhouse/providers/http_conf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_provider.g.dart';

enum PreferencesKey { darkMode, languageCode, serverAddress, timeout, useHttps }

@riverpod
PreferencesService preferencesService(PreferencesServiceRef ref) {
  return PreferencesService();
}

class PreferencesService {
  Future<void> setThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferencesKey.darkMode.name, isDarkMode);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferencesKey.darkMode.name) ?? false;
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferencesKey.languageCode.name, languageCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferencesKey.languageCode.name) ?? 'en';
  }

  Future<HttpConfigModel> getHttpConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String baseUrl =
        prefs.getString(PreferencesKey.serverAddress.name) ?? "1.1.1.1:8080";
    int timeout = prefs.getInt(PreferencesKey.timeout.name) ?? 5;
    bool useHttps = prefs.getBool(PreferencesKey.useHttps.name) ?? false;
    return HttpConfigModel(
        baseUrl: baseUrl,
        timeout: Duration(seconds: timeout),
        useHttps: useHttps);
  }

  Future<void> setHttpConfig(HttpConfigModel httpConfig) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        PreferencesKey.serverAddress.name, httpConfig.baseUrl);
    await prefs.setInt(
        PreferencesKey.timeout.name, httpConfig.timeout.inSeconds);
    await prefs.setBool(PreferencesKey.useHttps.name, httpConfig.useHttps);
  }
}
