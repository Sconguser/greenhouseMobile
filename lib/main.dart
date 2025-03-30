import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maker_greenhouse/providers/notification_service.dart';
import 'package:maker_greenhouse/providers/theme_notifier.dart';
import 'package:maker_greenhouse/shared/ui_constants.dart';
import 'generated/l10n.dart';
import 'providers/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final themeMode = ref.watch(themeNotifierProvider);
      final router = ref.watch(goRouterProvider);
      return MaterialApp.router(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
        title: 'Greenhouse@Makerspace',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode.value,
      );
    });
  }
}
