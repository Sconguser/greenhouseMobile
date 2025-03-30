import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/language_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:maker_greenhouse/providers/language_notifier.dart';
import 'package:maker_greenhouse/providers/theme_notifier.dart';

import '../../generated/l10n.dart';

class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return SwitchListTile(
        title: Text(S.of(context).settingsDarkTheme),
        secondary: const Icon(Icons.dark_mode),
        value: theme.value != null ? theme.value == ThemeMode.dark : false,
        onChanged: (_) =>
            {ref.read(themeNotifierProvider.notifier).toggleTheme()});
  }
}

class LanguagePick extends ConsumerWidget {
  const LanguagePick({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Language> supportedLanguages = S.delegate.supportedLocales
        .map((locale) => Language.fromIsoCode(locale.languageCode))
        .toList();
    final language = ref.watch(languageNotifierProvider);
    return SafeArea(

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: LanguagePickerDropdown(
          initialValue: Language.fromIsoCode(Intl.getCurrentLocale()),
          languages: supportedLanguages,
          onValuePicked: (Language language) {
            ref
                .read(languageNotifierProvider.notifier)
                .setLanguage(language.isoCode);
          },
        ),
      ),
    );
  }
}
