import 'package:go_router/go_router.dart';

import 'presentation/menu_screen.dart';

final menuRoutes = <RouteBase>[
  GoRoute(path: '/', builder: (_, _) => const MenuScreen()),
];
