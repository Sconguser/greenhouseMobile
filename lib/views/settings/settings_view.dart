import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/providers/language_notifier.dart';
import 'package:maker_greenhouse/views/settings/widgets.dart';

import '../../providers/routes.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key, required this.authNavButton});

  final bool authNavButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageNotifierProvider);
    return SafeArea(
      child: Column(
        children: [
          if (authNavButton)
            ElevatedButton(
                onPressed: () {
                  ref.read(goRouterProvider).go(AppRoutes.login.path);
                },
                child: Text("Go back")),
          const ThemeSwitch(),
          LanguagePick(),
          ServerConfig(),
        ],
      ),
    );
  }
}
