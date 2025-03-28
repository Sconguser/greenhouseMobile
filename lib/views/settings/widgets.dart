import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_picker/language_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:maker_greenhouse/providers/language_notifier.dart';
import 'package:maker_greenhouse/providers/theme_notifier.dart';

class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return SwitchListTile(
        title: const Text('Dark theme'),
        secondary: const Icon(Icons.dark_mode),
        value: theme.value != null ? theme.value == ThemeMode.dark : false,
        onChanged: (_) =>
            {ref.read(themeNotifierProvider.notifier).toggleTheme()});
  }
}

class LanguagePick extends ConsumerWidget {
  LanguagePick({super.key});

  ///TODO: moze z pliku?
  final supportedLanguages = [
    Languages.english,
    Languages.polish,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageNotifierProvider);
    return LanguagePickerDropdown(
      initialValue: language.value != null
          ? Language.fromIsoCode(language.value!.languageCode)
          : Languages.polish,
      languages: supportedLanguages,
      onValuePicked: (Language language) {
        ref
            .read(languageNotifierProvider.notifier)
            .setLanguage(language.isoCode);
      },
    );
  }
}
