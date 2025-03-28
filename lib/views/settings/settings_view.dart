import 'package:flutter/material.dart';
import 'package:maker_greenhouse/views/settings/widgets.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
