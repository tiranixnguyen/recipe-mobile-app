import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/about/about_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/clear_data/clear_data_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/policy/policy_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_screen.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

const onboardingLocation = '/onboarding';
const settingsLocation = '/settings';

/// Sửa dụng cụ & chế độ ăn từ Cài đặt (dùng lại màn Onboarding).
const kitchenEditLocation = '/settings/kitchen';
const feedbackLocation = '/settings/feedback';
const policyLocation = '/settings/policy';
const aboutLocation = '/settings/about';
const clearDataLocation = '/settings/clear-data';

/// Onboarding (`Onboarding`), Cài đặt (`Settings`) và các màn mở từ Cài đặt.
final systemRoutes = <RouteBase>[
  GoRoute(path: onboardingLocation, builder: (_, _) => const OnboardingScreen()),
  GoRoute(path: settingsLocation, builder: (_, _) => const SettingsScreen()),
  GoRoute(path: kitchenEditLocation, builder: (_, _) => const OnboardingScreen(editing: true)),
  // TODO(SYS-05): màn Góp ý (`Feedback`).
  GoRoute(
    path: feedbackLocation,
    builder: (_, _) => const ComingSoonScreen(title: SystemStrings.feedback),
  ),
  GoRoute(path: policyLocation, builder: (_, _) => const PolicyScreen()),
  GoRoute(path: aboutLocation, builder: (_, _) => const AboutScreen()),
  GoRoute(
    path: clearDataLocation,
    pageBuilder: (_, state) => _DialogPage(key: state.pageKey, child: const ClearDataScreen()),
  ),
];

/// Mở [child] như hộp thoại đè lên màn trước (bấm ra ngoài hoặc back là đóng).
class _DialogPage<T> extends Page<T> {
  const _DialogPage({super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) =>
      DialogRoute<T>(context: context, settings: this, builder: (_) => child);
}
