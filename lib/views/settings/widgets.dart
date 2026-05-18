import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:language_picker/language_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:maker_greenhouse/providers/http_conf.dart';
import 'package:maker_greenhouse/providers/language_notifier.dart';
import 'package:maker_greenhouse/providers/theme_notifier.dart';
import 'package:maker_greenhouse/views/greenhouses/widgets.dart';

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
    ref.watch(languageNotifierProvider);
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

class ServerConfig extends ConsumerStatefulWidget {
  const ServerConfig({super.key});

  @override
  ConsumerState<ServerConfig> createState() => _ServerConfigState();
}

class _ServerConfigState extends ConsumerState<ServerConfig> {
  final _formKey = GlobalKey<FormBuilderState>();

  final GlobalKey<FormBuilderFieldState> _serverAddressFieldKey =
      GlobalKey<FormBuilderFieldState>();

  final GlobalKey<FormBuilderFieldState> _timeoutDurationFieldKey =
      GlobalKey<FormBuilderFieldState>();

  final GlobalKey<FormBuilderFieldState> _useHttpsFieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(httpConfigProvider);
    return ExpansionTile(
      title: Text("Server config"),
      children: [FormBuilder(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 5),
                FormBuilderTextField(
                  key: _serverAddressFieldKey,
                  name: 'serverAddress',
                  decoration: InputDecoration(
                    labelText: "Server address",
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: S.of(context).authThisFieldCannotBeEmpty),
                  ]),
                  initialValue: config.value?.baseUrl,
                ),
                buildSizedBoxBetweenInputs(),
                FormBuilderTextField(
                  key: _timeoutDurationFieldKey,
                  name: 'timeout',
                  decoration: InputDecoration(
                    labelText: "Timeout duration in seconds",
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: S.of(context).authThisFieldCannotBeEmpty),
                    FormBuilderValidators.notZeroNumber(
                        errorText: "Needs to be a number bigger than 0"),
                  ]),
                  keyboardType: TextInputType.number,
                  initialValue: "${config.value?.timeout.inSeconds}",
                ),
                buildSizedBoxBetweenInputs(),
                FormBuilderCheckbox(
                  name: "useHttps",
                  key: _useHttpsFieldKey,
                  title: Text("Use https"),
                ),
                buildSizedBoxBetweenInputs(),
                ElevatedButton(
                  child: Text("Save"),
                  onPressed: () async {
                    _formKey.currentState?.validate();
                    if (_formKey.currentState != null &&
                        _formKey.currentState!.isValid) {
                      await ref.read(httpConfigProvider.notifier).changeConfig(
                          HttpConfigModel(
                              baseUrl: _serverAddressFieldKey.currentState!.value,
                              timeout: Duration(
                                  seconds: int.parse(_timeoutDurationFieldKey
                                      .currentState!.value)),
                              useHttps: _useHttpsFieldKey.currentState?.value ?? false));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Server config updated')),
                          );
                        }
                      }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    );
  }
}
