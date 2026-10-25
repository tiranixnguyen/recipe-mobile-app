import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_screen.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Đường dẫn tới màn Chi tiết món — feature khác dùng hàm này thay vì tự ghép chuỗi.
String recipeLocation(String id) => '/recipe/$id';

/// Màn Chuẩn bị nấu của món [id] (prototype `CookPrep`).
String cookPrepLocation(String id) => '${recipeLocation(id)}/prep';

/// Chi tiết món (`Detail`); chế độ nấu (`CookPrep` → `CookStep` → `CookDone`) thêm dưới route này.
final cookRoutes = <RouteBase>[
  GoRoute(
    path: '/recipe/:id',
    builder: (_, state) => DetailScreen(recipeId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'prep',
        builder: (_, _) => const ComingSoonScreen(title: CookStrings.prep),
      ),
    ],
  ),
];
