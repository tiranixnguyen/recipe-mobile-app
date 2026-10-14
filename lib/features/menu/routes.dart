import 'package:go_router/go_router.dart';

import '../../core/widgets/coming_soon_screen.dart';

final menuRoutes = <RouteBase>[
  GoRoute(
    path: '/',
    builder: (_, _) => const ComingSoonScreen(title: 'Menu'),
  ),
];
