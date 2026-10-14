import 'package:go_router/go_router.dart';

import '../features/detail/detail.dart';
import '../features/favorites/favorites.dart';
import '../features/menu/menu.dart';
import 'shell.dart';

/// Chỉ gộp routes do từng feature khai báo. Chủ feature sửa `routes.dart` của mình, không sửa file này.
GoRouter createRouter() => GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: menuRoutes),
        StatefulShellBranch(routes: favoritesRoutes),
      ],
    ),
    ...detailRoutes,
  ],
);
