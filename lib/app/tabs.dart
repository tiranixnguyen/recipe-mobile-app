import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_icon.dart';
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
  AppTab(label: AppStrings.tabDiscover, icon: AppIcons.compass, routes: discoverTabRoutes),
  AppTab(label: AppStrings.tabPantry, icon: AppIcons.fridge, routes: pantryTabRoutes),
  AppTab(label: AppStrings.tabPlan, icon: AppIcons.calendar, routes: planTabRoutes),
  AppTab(label: AppStrings.tabSaved, icon: AppIcons.bookmark, routes: savedTabRoutes),
];
