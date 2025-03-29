// routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maker_greenhouse/views/auth/auth_view.dart';
import 'package:maker_greenhouse/views/scaffold_with_navigator/scaffold_with_navigator.dart';
import 'package:maker_greenhouse/views/settings/settings_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../views/error/error_view.dart';
import '../views/greenhouses/controls_view.dart';
import '../views/splash/splash_view.dart';
import 'auth_notifier.dart';

part 'routes.g.dart';

enum AppRoutes {
  login,
  home,
  splash,
  settings,
  settingsUnauthorized,
}

extension AppRoutesExtension on AppRoutes {
  String get path => "/$name";
}

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash.path,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.splash.path,
      ),
      GoRoute(
        path: AppRoutes.splash.path,
        name: AppRoutes.splash.name,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashView(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        name: AppRoutes.login.name,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuthView(),
        ),
      ),
      ShellRoute(
          builder: (context, state, child) {
            return Scaffold(body: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.settingsUnauthorized.path,
              name: AppRoutes.settingsUnauthorized.name,
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const SettingsView(),
              ),
            ),
          ]),
      ShellRoute(
          builder: (context, state, child) {
            return ScaffoldWithNav(child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutes.home.path,
              name: AppRoutes.home.name,
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const ControlsView(),
              ),
            ),
            GoRoute(
              path: AppRoutes.settings.path,
              name: AppRoutes.settings.name,
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: const SettingsView(),
              ),
            ),
          ])
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isInitializing = authState.isLoading;
      final isAuthenticated = authState.value != null;
      final currentLocation = state.matchedLocation;

      debugPrint('''
      Redirect Check:
      - Location: $currentLocation
      - Auth Loading: $isInitializing
      - Authenticated: $isAuthenticated
      ''');

      // Initial app launch
      if (isInitializing) {
        return currentLocation == AppRoutes.splash.path
            ? null
            : AppRoutes.splash.path;
      }

      // Unauthenticated user
      if (!isAuthenticated && !_isPublicRoute(currentLocation)) {
        return currentLocation == AppRoutes.login.path
            ? null
            : AppRoutes.login.path;
      }

      // Authenticated user
      if (isAuthenticated) {
        if (currentLocation == AppRoutes.login.path ||
            currentLocation == AppRoutes.splash.path) {
          return AppRoutes.home.path;
        }
      }

      return null;
    },
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error ?? Exception('Unknown error'),
      onRetry: () => ref.invalidate(authNotifierProvider),
    ),
  );
}

bool _isPublicRoute(String path) => [
      AppRoutes.login.path,
      AppRoutes.settingsUnauthorized.path,
      '/unauthorized'
    ].contains(path);
