import 'package:go_router/go_router.dart';

import '../features/cook/cook.dart';
import '../features/discover/discover.dart';
import '../features/pantry/pantry.dart';
import '../features/plan/plan.dart';
import '../features/system/system.dart';
import 'shell.dart';
import 'splash_screen.dart';

const splashLocation = '/splash';

/// Chỉ gộp routes do từng feature khai báo. Chủ feature sửa `routes.dart` của mình, không sửa file này.
///
/// Tab (có bottom nav) nằm trong shell; màn còn lại (tìm kiếm, chi tiết, cài đặt…) mở toàn màn hình.
GoRouter createRouter() => GoRouter(
  initialLocation: splashLocation,
  routes: [
    GoRoute(path: splashLocation, builder: (_, _) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: discoverTabRoutes),
        StatefulShellBranch(routes: pantryTabRoutes),
        StatefulShellBranch(routes: planTabRoutes),
        StatefulShellBranch(routes: savedTabRoutes),
      ],
    ),
    ...discoverRoutes,
    ...cookRoutes,
    ...planRoutes,
    ...systemRoutes,
  ],
);
