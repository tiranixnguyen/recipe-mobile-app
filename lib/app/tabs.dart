import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../features/discover/discover.dart';
import '../features/pantry/pantry.dart';
import '../features/plan/plan.dart';
import 'strings.dart';

class AppTab {
  const AppTab({required this.label, required this.icon, required this.routes});

  final String label;
  final IconData icon;
  final List<RouteBase> routes;
}

/// Bốn tab theo component `BottomNav`; thứ tự ở đây là thứ tự trên thanh điều hướng.
/// Router dựng branch và shell dựng nút đều từ list này.
final appTabs = [
  AppTab(label: AppStrings.tabDiscover, icon: Symbols.explore_rounded, routes: discoverTabRoutes),
  AppTab(label: AppStrings.tabPantry, icon: Symbols.kitchen_rounded, routes: pantryTabRoutes),
  AppTab(label: AppStrings.tabPlan, icon: Symbols.calendar_month_rounded, routes: planTabRoutes),
  AppTab(label: AppStrings.tabSaved, icon: Symbols.bookmark_rounded, routes: savedTabRoutes),
];
