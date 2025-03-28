import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:maker_greenhouse/providers/routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_notifier.g.dart';

@riverpod
class NavigationNotifier extends _$NavigationNotifier {
  @override
  int build() {
    return _init();
  }

  int _init() {
    ref.listen(goRouterProvider, (_, router) {
      state = _calculateSelectedIndex(router);
    });
    return _calculateSelectedIndex(ref.read(goRouterProvider));
  }

  int _calculateSelectedIndex(GoRouter router) {
    final location = router.routeInformationProvider.value.uri.toString();
    debugPrint("deebil + $location");
    if (location.startsWith(AppRoutes.home.path)) return 0;
    // if (location.startsWith(AppRoutes.analytics.path)) return 1;
    if (location.startsWith(AppRoutes.settings.path)) return 2;
    return 0;
  }

  void navigate(int index) {
    final path = switch (index) {
      0 => AppRoutes.home.path,
      // 1 => AppRoutes.analytics.path,
      2 => AppRoutes.settings.path,
      _ => AppRoutes.home.path,
    };
    ref.read(goRouterProvider).go(path);
  }
}
