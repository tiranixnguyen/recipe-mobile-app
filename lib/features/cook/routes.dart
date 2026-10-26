import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/widgets/coming_soon_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/prep/prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/step/step_screen.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Đường dẫn tới màn Chi tiết món — feature khác dùng hàm này thay vì tự ghép chuỗi.
String recipeLocation(String id) => '/recipe/$id';

/// Màn Chuẩn bị nấu của món [id] (prototype `CookPrep`).
String cookPrepLocation(String id) => '${recipeLocation(id)}/prep';

/// Nấu từng bước món [id] (prototype `CookStep`), mở ở bước đang dở của phiên nấu.
String cookStepLocation(String id) => '${recipeLocation(id)}/cook';

/// Nấu xong món [id] (prototype `CookDone`).
String cookDoneLocation(String id) => '${recipeLocation(id)}/done';

/// Chi tiết món (`Detail`) và chế độ nấu một món: `CookPrep` → `CookStep` → `CookDone`.
final cookRoutes = <RouteBase>[
  GoRoute(
    path: '/recipe/:id',
    builder: (_, state) => DetailScreen(recipeId: state.pathParameters['id']!),
    routes: [
      GoRoute(
        path: 'prep',
        builder: (_, state) => PrepScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'cook',
        builder: (_, state) => StepScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: 'done',
        builder: (_, _) => const ComingSoonScreen(title: CookStrings.cookDone),
      ),
    ],
  ),
];
