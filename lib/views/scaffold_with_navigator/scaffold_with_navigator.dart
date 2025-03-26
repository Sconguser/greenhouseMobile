import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maker_greenhouse/providers/navigation_notifier.dart';

import '../../providers/routes.dart';

class ScaffoldWithNav extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<ScaffoldWithNav> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final selectedIndex = ref.watch(navigationNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Greenhouse Control')),
      drawer: _buildDrawer(ref),
      body: widget.child,
      bottomNavigationBar: _buildBottomNavBar(router, selectedIndex),
    );
  }

  Widget _buildBottomNavBar(GoRouter router, int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) =>
          ref.read(navigationNotifierProvider.notifier).navigate(index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Controls',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildDrawer(WidgetRef ref) {
    return Drawer(
      child: ListView(
        children: [
          _buildDrawerItem(0, Icons.home, 'Controls', ref),
          _buildDrawerItem(1, Icons.analytics, 'Analytics', ref),
          _buildDrawerItem(2, Icons.settings, 'Settings', ref),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
      int index, IconData icon, String title, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () =>
          ref.read(navigationNotifierProvider.notifier).navigate(index),
    );
  }
}
