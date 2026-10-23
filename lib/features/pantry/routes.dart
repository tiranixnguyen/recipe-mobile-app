import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/pantry/strings.dart';

/// Tab Tủ đồ (prototype `Pantry`).
final pantryTabRoutes = <RouteBase>[
  GoRoute(
    path: '/pantry',
    builder: (_, _) => const ComingSoonScreen(title: PantryStrings.title),
  ),
];
