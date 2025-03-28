import 'dart:ui';

import 'package:maker_greenhouse/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_notifier.g.dart';

@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  late final PreferencesService _preferencesService;

  @override
  Future<Locale> build() async {
    _preferencesService = ref.read(preferencesServiceProvider);
    final languageCode = await _preferencesService.getLanguage();
    return Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    state = AsyncValue.loading();
    await _preferencesService.setLanguage(languageCode);
    state = AsyncValue.data(Locale(languageCode));
  }
}
