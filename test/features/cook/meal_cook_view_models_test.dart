import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_done/meal_done_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_step/meal_step_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

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
        cookClockProvider.overrideWithValue(() => now),
        wakelockProvider.overrideWithValue(wakelock),
        notificationServiceProvider.overrideWithValue(notifications),
        appInForegroundProvider.overrideWithValue(() => true),
        appReviewProvider.overrideWithValue(review),
      ],
    );
    addTearDown(container.dispose);
  }

  late final ProviderContainer container;
  final wakelock = FakeWakelock();
  final notifications = FakeNotificationService();
  final review = FakeAppReview();
  var now = DateTime(2026, 10, 27, 18);

  Future<void> plan({int servings = 1}) async {
    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung', _day, Meal.dinner, servings: servings);
    await plan.addToPlan('canh', _day, Meal.dinner, servings: 2);
  }

  Future<void> load<T>(ProviderListenable<T> provider) async {
    container.listen(provider, (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
  }
}

void main() {
  group('Chuẩn bị cả bữa', () {
    final provider = mealPrepViewModelProvider(_slot);

    test('thứ tự gợi ý món lâu trước, khẩu phần lớn nhất, đồ trong tủ cộng cả bữa', () async {
      final env = _Env();
      await env.plan();
      await env.container.read(pantryItemsProvider.notifier).addToPantry('egg');
      await env.load(provider);
      final state = env.container.read(provider).requireValue;

      expect(state.dishes.map((d) => d.recipe.id), ['canh', 'trung']);
      expect(state.reordered, isFalse);
      expect(state.servings, 2);
      expect(state.minutes, 35);
      expect(state.tools, 'Bếp từ');
      expect(state.gather.map((g) => (g.name, g.amountText)), [('Trứng gà', '5 quả')]);
      expect(state.gather.single.recipeIds, ['canh', 'trung']);
      expect(state.missing.map((m) => m.name), ['cà chua', 'hành lá', 'ớt']);
    });

    test(
      'kéo đổi thứ tự, Dùng thứ tự gợi ý; Bắt đầu mở phiên cả bữa theo thứ tự đang chọn',
      () async {
        final env = _Env();
        await env.plan();
        await env.load(provider);
        final viewModel = env.container.read(provider.notifier);

        viewModel.move(1, 0);
        var state = env.container.read(provider).requireValue;
        expect(state.dishes.map((d) => d.recipe.id), ['trung', 'canh']);
        expect(state.reordered, isTrue);
        viewModel.useSuggestedOrder();
        expect(env.container.read(provider).requireValue.reordered, isFalse);

        viewModel.move(0, 1);
        viewModel.setServings(3);
        await viewModel.start();
        final session = env.container.read(cookSessionProvider)!;
        expect(session.dishes, [(recipeId: 'trung', servings: 3), (recipeId: 'canh', servings: 3)]);
        expect(session.planned, _slot);
        state = env.container.read(provider).requireValue;
        expect(state.dishes.first.servings, 3);
      },
    );

    test('Thêm vào đi chợ mọi món với khẩu phần cả bữa', () async {
      final env = _Env();
      await env.plan();
      await env.load(provider);
      await env.container.read(provider.notifier).addToShopping();
      expect(env.container.read(shoppingProvider).map((r) => (r.recipeId, r.servings)), [
        ('canh', 2),
        ('trung', 2),
      ]);
    });

    test('bữa trống thì lỗi MealNotFound', () async {
      final env = _Env();
      await env.load(provider);
      expect(env.container.read(provider).error, isA<MealNotFound>());
    });
  });

  group('Từng bước cả bữa', () {
    Future<_Env> started() async {
      final env = _Env();
      await env.container.read(cookSessionProvider.notifier).startMeal([
        (recipeId: 'canh', servings: 2),
        (recipeId: 'trung', servings: 2),
      ], _slot);
      await env.load(mealStepViewModelProvider);
      return env;
    }

    MealStepState state(_Env env) => env.container.read(mealStepViewModelProvider).requireValue;
    MealStepViewModel viewModel(_Env env) => env.container.read(mealStepViewModelProvider.notifier);

    test('qua bước, sang món sau thì món trước xong; Bước trước về bước cuối món trước', () async {
      final env = await started();
      expect((state(env).current, state(env).index, state(env).isFirst), (0, 0, true));
      expect(env.wakelock.enabled, isTrue);

      await viewModel(env).next();
      await viewModel(env).next();
      expect((state(env).isLastStep, state(env).isLastDish), (true, false));
      await viewModel(env).next();
      expect((state(env).current, state(env).index), (1, 0));
      expect(state(env).finished, {0});

      await viewModel(env).previous();
      expect((state(env).current, state(env).index), (0, 2));
    });

    test('bấm tab món giữ bước riêng của từng món', () async {
      final env = await started();
      await viewModel(env).next();
      await viewModel(env).selectDish(1);
      await viewModel(env).next();
      await viewModel(env).next();
      await viewModel(env).selectDish(0);
      expect((state(env).current, state(env).index), (0, 1));
      expect(state(env).positions, [1, 2]);
      expect(state(env).ingredients.first, (name: 'Cà chua', amountText: '2 quả'));
    });

    test('đồng hồ của món khác vẫn hiện khi đang chạy; key riêng theo món', () async {
      final env = await started();
      await viewModel(env).timerChanged(0, 1, StepTimerStatus.running);
      await viewModel(env).selectDish(1);
      expect(state(env).showsTimer(0, 1), isTrue);
      expect(state(env).showsTimer(1, 1), isFalse);
      expect(env.notifications.timers.keys, [cookTimerKey(0, 1)]);
      expect(state(env).timedSteps, [(0, 1), (1, 1), (1, 2)]);
    });

    test('Xong cả bữa: mọi món xong, huỷ lịch báo', () async {
      final env = await started();
      await viewModel(env).timerChanged(1, 2, StepTimerStatus.running);
      await viewModel(env).finishMeal();
      expect(env.container.read(cookSessionProvider)!.isDone, isTrue);
      expect(env.notifications.timers, isEmpty);
    });

    test('không có phiên cả bữa thì lỗi MealNotFound', () async {
      final env = _Env();
      await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 1);
      await env.load(mealStepViewModelProvider);
      expect(env.container.read(mealStepViewModelProvider).error, isA<MealNotFound>());
    });
  });

  group('Hoàn thành cả bữa', () {
    test('chấm từng món, bỏ đồ đã tick, đánh dấu bữa đã nấu, xoá phiên', () async {
      final env = _Env();
      await env.plan();
      for (final id in ['egg', 'tomato']) {
        await env.container.read(pantryItemsProvider.notifier).addToPantry(id);
      }
      await env.container.read(cookSessionProvider.notifier).startMeal([
        (recipeId: 'canh', servings: 2),
        (recipeId: 'trung', servings: 2),
      ], _slot);
      await env.load(mealDoneViewModelProvider);
      final viewModel = env.container.read(mealDoneViewModelProvider.notifier);
      var state = env.container.read(mealDoneViewModelProvider).requireValue;
      expect((state.servings, state.minutes), (2, 35));
      expect(state.used.map((u) => (u.name, u.note)), [
        ('Cà chua', 'Đã dùng 2 quả'),
        ('Trứng gà', 'Đã dùng 5 quả'),
      ]);

      viewModel.rate(0, CookRating.good);
      viewModel.rate(1, CookRating.bad);
      viewModel.rate(1, CookRating.bad);
      viewModel.rate(1, CookRating.ok);
      viewModel.toggleUsedUp('tomato');
      state = env.container.read(mealDoneViewModelProvider).requireValue;
      expect(state.ratings, {0: CookRating.good, 1: CookRating.ok});

      await viewModel.finish();
      expect(env.container.read(pantryItemsProvider), {'egg'});
      expect(env.container.read(cookHistoryProvider).map((r) => (r.recipeId, r.rating)), [
        ('canh', CookRating.good),
        ('trung', CookRating.ok),
      ]);
      expect(env.container.read(plannedMealsProvider).every((p) => p.cooked), isTrue);
      expect(env.container.read(cookSessionProvider), isNull);
      // Màn vẫn giữ bữa vừa nấu tới khi rời đi.
      expect(env.container.read(mealDoneViewModelProvider).hasValue, isTrue);
    });
  });
}
