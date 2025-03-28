import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_provider.g.dart';

enum PreferencesKey { darkMode, languageCode }

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
}
