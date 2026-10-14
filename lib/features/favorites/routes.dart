import 'package:go_router/go_router.dart';

import 'presentation/favorites_screen.dart';

final favoritesRoutes = <RouteBase>[
  GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
];
