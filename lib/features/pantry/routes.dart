import 'package:go_router/go_router.dart';

import '../../core/widgets/coming_soon_screen.dart';
import 'strings.dart';

/// Tab Tủ đồ (prototype `Pantry`).
final pantryTabRoutes = <RouteBase>[
  GoRoute(
    path: '/pantry',
    builder: (_, _) => const ComingSoonScreen(title: PantryStrings.title),
  ),
];
