import 'dart:ui';

import 'package:maker_greenhouse/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../generated/l10n.dart';

part 'language_notifier.g.dart';

@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  late final PreferencesService _preferencesService;

  @override
  Future<Locale> build() async {
    _preferencesService = ref.read(preferencesServiceProvider);
    final languageCode = await _preferencesService.getLanguage();
    S.load(Locale.fromSubtags(languageCode: languageCode));
    return Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    state = AsyncValue.loading();
    await _preferencesService.setLanguage(languageCode);
    S.load(Locale.fromSubtags(languageCode: languageCode));
    state = AsyncValue.data(Locale(languageCode));
  }
}
