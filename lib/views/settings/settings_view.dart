import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/providers/language_notifier.dart';
import 'package:maker_greenhouse/views/settings/widgets.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageNotifierProvider);
    return Container(
      child: Column(
        children: [
          const ThemeSwitch(),
          LanguagePick(),
        ],
      ),
    );
  }
}
