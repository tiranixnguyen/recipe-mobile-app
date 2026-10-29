import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/done/done_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_done/meal_done_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_step/meal_step_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/prep/prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/step/step_screen.dart';

/// Đường dẫn tới màn Chi tiết món — feature khác dùng hàm này thay vì tự ghép chuỗi.
String recipeLocation(String id) => '/recipe/$id';

/// Màn Chuẩn bị nấu của món [id] (prototype `CookPrep`).
String cookPrepLocation(String id) => '${recipeLocation(id)}/prep';

/// Nấu từng bước món [id] (prototype `CookStep`), mở ở bước đang dở của phiên nấu.
String cookStepLocation(String id) => '${recipeLocation(id)}/cook';

/// Nấu xong món [id] (prototype `CookDone`).
String cookDoneLocation(String id) => '${recipeLocation(id)}/done';

/// Nấu cả bữa [meal] ngày [day] trong Thực đơn (prototype `MealCookPrep`).
String mealCookLocation(DateTime day, Meal meal) => Uri(
  path: _mealCookPath,
  queryParameters: {
    'day': '${day.year.toString().padLeft(4, '0')}-${_two(day.month)}-${_two(day.day)}',
    'meal': meal.id,
  },
).toString();

String _two(int n) => n.toString().padLeft(2, '0');

const _mealCookPath = '/meal-cook';

/// Nấu cả bữa từng bước (`MealCookStep`), theo phiên nấu đang dở.
const mealCookStepLocation = '$_mealCookPath/step';

/// Nấu xong cả bữa (`MealCookDone`).
const mealCookDoneLocation = '$_mealCookPath/done';

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
        builder: (_, state) => DoneScreen(recipeId: state.pathParameters['id']!),
      ),
    ],
  ),
  // Nấu cả bữa: `MealCookPrep` → `MealCookStep` → `MealCookDone`.
  GoRoute(
    path: _mealCookPath,
    builder: (_, state) {
      final day = DateTime.tryParse(state.uri.queryParameters['day'] ?? '');
      final meal = Meal.tryParse(state.uri.queryParameters['meal'] ?? '');
      if (day == null || meal == null) return const NoMealScreen();
      return MealPrepScreen(slot: (day: day, meal: meal));
    },
    routes: [
      GoRoute(path: 'step', builder: (_, _) => const MealStepScreen()),
      GoRoute(path: 'done', builder: (_, _) => const MealDoneScreen()),
    ],
  ),
];
