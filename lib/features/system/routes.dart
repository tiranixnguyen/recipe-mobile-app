import 'package:go_router/go_router.dart';

import '../../core/widgets/coming_soon_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'strings.dart';

const onboardingLocation = '/onboarding';
const settingsLocation = '/settings';

/// Onboarding (`Onboarding`) và Cài đặt (`Settings`); About, Policy, Feedback, ClearData thêm ở đây.
final systemRoutes = <RouteBase>[
  GoRoute(path: onboardingLocation, builder: (_, _) => const OnboardingScreen()),
  GoRoute(
    path: settingsLocation,
    builder: (_, _) => const ComingSoonScreen(title: SystemStrings.settings),
  ),
];
