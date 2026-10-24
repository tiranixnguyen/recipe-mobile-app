import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_screen.dart';

/// Tab Tủ đồ. Là tab nên mở bằng `context.go`, không `push`.
const pantryLocation = '/pantry';

/// Tab Tủ đồ (prototype `Pantry`).
final pantryTabRoutes = <RouteBase>[
  GoRoute(path: pantryLocation, builder: (_, _) => const PantryScreen()),
];
