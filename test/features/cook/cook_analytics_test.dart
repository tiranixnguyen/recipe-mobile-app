import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/done/done_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_done/meal_done_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/prep/prep_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

import '../../core/fake_analytics.dart';
import 'fakes.dart';
import 'fixtures.dart';

final _day = DateTime(2026, 10, 27);
final _slot = (day: _day, meal: Meal.dinner);

class _Env {
  _Env() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const [cookRecipeFixture, soupRecipeFixture]),
        ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
        cookClockProvider.overrideWithValue(() => DateTime(2026, 10, 27, 19)),
        appReviewProvider.overrideWithValue(FakeAppReview()),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
  }

  late final ProviderContainer container;
  final analytics = FakeAnalytics();

  Future<void> load<T>(ProviderListenable<T> provider) async {
    container.listen(provider, (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
  }

  /// `[tên, tham số]` theo thứ tự ghi; dùng list để `expect` so sánh map theo nội dung.
  List<List<Object?>> get events => [
    for (final (i, e) in analytics.events.indexed) [e, analytics.params[i]],
  ];
}

void main() {
  test('view_recipe ghi một lần khi mở Chi tiết, tủ đồ đổi không ghi lại', () async {
    final env = _Env();
    await env.load(detailViewModelProvider('trung'));
    await env.container.read(pantryItemsProvider.notifier).addToPantry('egg');
    env.container.read(detailViewModelProvider('trung'));

    expect(env.events, [
      [
        'view_recipe',
        {'recipe': 'trung'},
      ],
    ]);
  });

  test('start_cooking một món kèm khẩu phần và số bước', () async {
    final env = _Env();
    final provider = prepViewModelProvider('trung');
    await env.load(provider);
    env.container.read(provider.notifier).setServings(3);
    await env.container.read(provider.notifier).start();

    expect(env.events, [
      [
        'start_cooking',
        {
          'servings': 3,
          'steps': cookRecipeFixture.steps.length,
          'meal_dishes': 1,
        },
      ],
    ]);
  });

  test('start_cooking cả bữa đếm bước mọi món', () async {
    final env = _Env();
    final plan = env.container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', _day, Meal.dinner);
    await plan.addToPlan('canh', _day, Meal.dinner, servings: 2);
    final provider = mealPrepViewModelProvider(_slot);
    await env.load(provider);
    await env.container.read(provider.notifier).start();

    expect(env.events, [
      [
        'start_cooking',
        {
          'servings': 2,
          'steps': cookRecipeFixture.steps.length + soupRecipeFixture.steps.length,
          'meal_dishes': 2,
        },
      ],
    ]);
  });

  test('finish_cooking và rate_recipe khi xong một món', () async {
    final env = _Env();
    await env.container.read(pantryItemsProvider.notifier).addToPantry('egg');
    await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 1);
    final provider = doneViewModelProvider('trung');
    await env.load(provider);
    final viewModel = env.container.read(provider.notifier);
    viewModel.toggleUsedUp('egg');
    viewModel.rate(CookRating.bad);
    await viewModel.finish();

    expect(env.events, [
      [
        'finish_cooking',
        {'used_up': 1, 'rated': true, 'meal_dishes': 1},
      ],
      [
        'rate_recipe',
        {'rating': 'bad'},
      ],
    ]);
  });

  test('không chấm thì không có rate_recipe', () async {
    final env = _Env();
    await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 1);
    final provider = doneViewModelProvider('trung');
    await env.load(provider);
    await env.container.read(provider.notifier).finish();

    expect(env.events, [
      [
        'finish_cooking',
        {'used_up': 0, 'rated': false, 'meal_dishes': 1},
      ],
    ]);
  });

  test('xong cả bữa: một finish_cooking, mỗi món đã chấm một rate_recipe', () async {
    final env = _Env();
    final plan = env.container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', _day, Meal.dinner);
    await plan.addToPlan('canh', _day, Meal.dinner);
    await env.container.read(cookSessionProvider.notifier).startMeal([
      (recipeId: 'canh', servings: 1),
      (recipeId: 'trung', servings: 1),
    ], _slot);
    await env.load(mealDoneViewModelProvider);
    final viewModel = env.container.read(mealDoneViewModelProvider.notifier);
    viewModel.rate(0, CookRating.good);
    await viewModel.finish();

    expect(env.events, [
      [
        'finish_cooking',
        {'used_up': 0, 'rated': true, 'meal_dishes': 2},
      ],
      [
        'rate_recipe',
        {'rating': 'good'},
      ],
    ]);
  });
}
