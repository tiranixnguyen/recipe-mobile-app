import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'strings.dart';

/// Bốn tab theo component `BottomNav`: Khám phá · Tủ đồ · Thực đơn · Đã lưu.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.explore_rounded),
            selectedIcon: Icon(Symbols.explore_rounded, fill: 1),
            label: AppStrings.tabDiscover,
          ),
          NavigationDestination(
            icon: Icon(Symbols.kitchen_rounded),
            selectedIcon: Icon(Symbols.kitchen_rounded, fill: 1),
            label: AppStrings.tabPantry,
          ),
          NavigationDestination(
            icon: Icon(Symbols.calendar_month_rounded),
            selectedIcon: Icon(Symbols.calendar_month_rounded, fill: 1),
            label: AppStrings.tabPlan,
          ),
          NavigationDestination(
            icon: Icon(Symbols.bookmark_rounded),
            selectedIcon: Icon(Symbols.bookmark_rounded, fill: 1),
            label: AppStrings.tabSaved,
          ),
        ],
      ),
    );
  }
}
