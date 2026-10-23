import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_screen.dart';
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
  // TODO(SYS-04): màn Chính sách (`Policy`), Giới thiệu (`About`), Xoá dữ liệu (`ClearData`).
  GoRoute(
    path: policyLocation,
    builder: (_, _) => const ComingSoonScreen(title: SystemStrings.policy),
  ),
  GoRoute(
    path: aboutLocation,
    builder: (_, _) => const ComingSoonScreen(title: SystemStrings.about),
  ),
  GoRoute(
    path: clearDataLocation,
    builder: (_, _) => const ComingSoonScreen(title: SystemStrings.clearData),
  ),
];
