import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'views/add_plant_view/add_plant_view.dart';
import 'views/auth/auth_view.dart';
import 'views/controls_view/controls_view.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maker Greenhouse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScaffold(body: AuthView()),
      routes: {
        '/add': (context) => const AddPlantView(),
        '/auth': (context) => const AuthView(),
        '/controls': (context) => const ControlsView(),
      },
    );
  }
}

class MainScaffold extends StatelessWidget {
  final Widget body;

  const MainScaffold({Key? key, required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: body,
      ),
    );
  }
}
