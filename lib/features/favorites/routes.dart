import 'package:go_router/go_router.dart';

import '../../core/widgets/coming_soon_screen.dart';

final favoritesRoutes = <RouteBase>[
  GoRoute(
    path: '/favorites',
    builder: (_, _) => const ComingSoonScreen(title: 'Yêu thích'),
  ),
];
