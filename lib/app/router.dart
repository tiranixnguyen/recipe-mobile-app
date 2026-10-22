import 'package:go_router/go_router.dart';

import '../features/cook/cook.dart';
import '../features/discover/discover.dart';
import '../features/plan/plan.dart';
import '../features/system/system.dart';
import 'shell.dart';
import 'splash_screen.dart';
import 'tabs.dart';

const splashLocation = '/splash';

/// Chỉ gộp routes do từng feature khai báo. Chủ feature sửa `routes.dart` của mình, không sửa file này.
///
/// Tab (có bottom nav) nằm trong shell; màn còn lại (tìm kiếm, chi tiết, cài đặt…) mở toàn màn hình,
/// mở bằng `context.push`, không dùng `go` (`go` bỏ mất shell, bấm back là thoát app).
///
/// Chưa qua Onboarding thì mọi route (deep link, chạm thông báo…) đều bị chuyển về Onboarding.
GoRouter createRouter({required bool Function() isOnboarded}) => GoRouter(
  initialLocation: splashLocation,
  redirect: (_, state) {
    final path = state.uri.path;
    if (path == splashLocation || path == onboardingLocation || isOnboarded()) return null;
    return onboardingLocation;
  },
  routes: [
    GoRoute(path: splashLocation, builder: (_, _) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [for (final tab in appTabs) StatefulShellBranch(routes: tab.routes)],
    ),
    ...discoverRoutes,
    ...cookRoutes,
    ...planRoutes,
    ...systemRoutes,
  ],
);
