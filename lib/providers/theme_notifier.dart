import 'package:flutter/material.dart';
import 'package:maker_greenhouse/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_notifier.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  late final PreferencesService _preferencesService;

  @override
  Future<ThemeMode> build() async {
    _preferencesService = ref.read(preferencesServiceProvider);
    final isDarkMode = await _preferencesService.getThemeMode();
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    state = AsyncValue.loading();
    final currentTheme = await build();
    final isDarkMode = currentTheme == ThemeMode.dark;
    await _preferencesService.setThemeMode(!isDarkMode);
    state = AsyncValue.data(!isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}
