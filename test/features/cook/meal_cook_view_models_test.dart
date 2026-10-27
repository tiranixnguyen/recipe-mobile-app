import 'dart:convert';

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
import 'package:recipe_mobile_app/features/cook/strings.dart';
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
        cookRandomProvider.overrideWithValue(FakeRandom(2)),
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
      expect((state.hasPrep, state.prepMinutes, state.cookMinutes), (true, 8, 27));
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
        // Bữa có việc sơ chế: bắt đầu ở chặng Sơ chế.
        expect(session.inPrep, isTrue);
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
    Future<_Env> started({bool prep = false, List<String> dishes = const ['canh', 'trung']}) async {
      final env = _Env();
      await env.container
          .read(cookSessionProvider.notifier)
          .startMeal([for (final id in dishes) (recipeId: id, servings: 2)], _slot, prep: prep);
      await env.load(mealStepViewModelProvider);
      return env;
    }

    MealStepState state(_Env env) => env.container.read(mealStepViewModelProvider).requireValue;
    MealStepViewModel viewModel(_Env env) => env.container.read(mealStepViewModelProvider.notifier);
    PrepItem prepItem(_Env env, String id) => state(env).prep.firstWhere((p) => p.id == id);

    test(
      'chặng Sơ chế: việc gộp theo nguyên liệu, cùng cách một việc, khác cách thành việc con',
      () async {
        final env = await started(prep: true);
        final s = state(env);
        expect((s.inPrep, s.isFirst, s.prepMinutes), (true, true, 8));
        expect(s.prep, const [
          PrepItem(
            id: 'tomato',
            ingredient: 'Cà chua',
            action: 'Bổ múi cau',
            amountText: '2 quả',
            dishes: [(name: 'Canh cà chua trứng', share: null)],
          ),
          PrepItem(
            id: 'scallion',
            ingredient: 'Hành lá',
            action: '',
            amountText: '3 nắm',
            children: [
              PrepItem(
                id: 'scallion/Cắt khúc',
                ingredient: 'Hành lá',
                action: 'Cắt khúc',
                amountText: '1 nắm',
                dishes: [(name: 'Canh cà chua trứng', share: null)],
              ),
              PrepItem(
                id: 'scallion/Thái nhỏ',
                ingredient: 'Hành lá',
                action: 'Thái nhỏ',
                amountText: '2 nắm',
                dishes: [(name: 'Trứng chiên hành', share: null)],
              ),
            ],
          ),
          PrepItem(
            id: 'egg',
            ingredient: 'Trứng gà',
            action: 'Đập ra bát rồi đánh tan',
            amountText: '5 quả',
            dishes: [
              (name: 'Canh cà chua trứng', share: '1 quả'),
              (name: 'Trứng chiên hành', share: '4 quả'),
            ],
          ),
        ]);
        expect((s.prepDoneCount, s.prepTotal, s.prepFinished), (0, 4, false));
      },
    );

    test(
      'tick việc con thì cha lửng rồi tự tick; bấm cha tick hoặc bỏ hết; tiến độ theo việc lá',
      () async {
        final env = await started(prep: true);
        final scallion = prepItem(env, 'scallion');

        await viewModel(env).togglePrep(scallion.children.first);
        expect(state(env).checkedOf(scallion), isNull);
        expect(state(env).prepDoneCount, 1);
        await viewModel(env).togglePrep(scallion.children.last);
        expect(state(env).checkedOf(scallion), isTrue);

        await viewModel(env).togglePrep(scallion);
        expect(state(env).checkedOf(scallion), isFalse);
        expect(state(env).prepDone, isEmpty);
        await viewModel(env).togglePrep(scallion.children.first);
        await viewModel(env).togglePrep(scallion);
        expect(state(env).prepDone, {'scallion/Cắt khúc', 'scallion/Thái nhỏ'});

        for (final id in ['tomato', 'egg']) {
          await viewModel(env).togglePrep(prepItem(env, id));
        }
        expect((state(env).prepDoneCount, state(env).prepFinished), (4, true));
        // Tick lưu trong phiên: thoát rồi mở lại vẫn còn.
        expect(env.container.read(cookSessionProvider)!.prepDone, hasLength(4));
      },
    );

    test('Bắt đầu nấu khi chưa tick đủ; món chỉ còn bước đứng bếp; Bước trước về Sơ chế', () async {
      final env = await started(prep: true);
      await viewModel(env).next();
      var s = state(env);
      expect((s.inPrep, s.current, s.index, s.isFirst), (false, 0, 0, false));
      expect(s.steps.map((e) => e.step.text), [
        'Xào cà chua',
        'Đổ nước, đun sôi',
        'Đổ trứng, tắt bếp',
      ]);
      expect(s.step.text, 'Xào cà chua');

      await viewModel(env).previous();
      expect(state(env).inPrep, isTrue);

      // Từ chặng Sơ chế bấm tab món 2, rồi tab Sơ chế.
      await viewModel(env).selectDish(1);
      s = state(env);
      expect((s.inPrep, s.current, s.step.text), (false, 1, 'Làm nóng dầu'));
      await viewModel(env).showPrep();
      expect(state(env).inPrep, isTrue);
      await viewModel(env).selectDish(1);
      expect((state(env).inPrep, state(env).current), (false, 1));
    });

    test('phiên cũ không có inPrep, prepDone vẫn đọc được, vào thẳng bước nấu', () async {
      final env = _Env();
      await env.container
          .read(localStoreProvider)
          .writeString(
            'cook.session',
            jsonEncode({
              'dishes': [
                {'recipeId': 'canh', 'servings': 2},
                {'recipeId': 'trung', 'servings': 2},
              ],
              'current': 0,
              'positions': [1, 0],
              'finished': <int>[],
              'planned': {'day': '2026-10-27', 'meal': 'dinner'},
              'startedAt': env.now.toIso8601String(),
            }),
          );
      env.container.invalidate(cookSessionProvider);
      await env.load(mealStepViewModelProvider);
      final s = state(env);
      expect((s.inPrep, s.prepDone.isEmpty, s.index), (false, true, 1));
      expect(s.hasPrep, isTrue);
    });

    test('qua bước, sang món sau thì món trước xong; Bước trước về bước cuối món trước', () async {
      final env = await started();
      expect((state(env).current, state(env).index, state(env).inPrep), (0, 0, false));
      // Bữa có việc sơ chế: bước đầu món đầu còn lùi về chặng Sơ chế được.
      expect(state(env).isFirst, isFalse);
      expect(env.wakelock.enabled, isTrue);

      await viewModel(env).next();
      await viewModel(env).next();
      expect(state(env).isLastStep, isTrue);
      await viewModel(env).next();
      expect((state(env).current, state(env).index), (1, 0));
      expect(state(env).finished, {0});

      await viewModel(env).previous();
      expect((state(env).current, state(env).index), (0, 2));
    });

    test('Xong sơ chế khi chưa tick đủ: tick hết mọi việc, vào món 1', () async {
      final env = await started(prep: true);
      await viewModel(env).togglePrep(state(env).prep.first);
      await viewModel(env).selectDish(1);
      await viewModel(env).showPrep();
      expect(state(env).prepFinished, isFalse);
      await viewModel(env).finishPrep();
      final s = state(env);
      expect((s.prepFinished, s.prepDoneCount, s.inPrep, s.current), (true, 4, false, 0));
    });

    test('Xong món n sang món chưa xong kế tiếp, bỏ qua món đã nhảy tab nấu xong', () async {
      final env = await started(dishes: ['canh', 'trung', 'canh']);
      expect(state(env).unfinished, [
        'Canh cà chua trứng',
        'Trứng chiên hành',
        'Canh cà chua trứng',
      ]);

      // Nhảy tab nấu xong món 2 trước: "Xong món 2" sang món 3.
      await viewModel(env).selectDish(1);
      for (var i = 0; i < 3; i++) {
        await viewModel(env).next();
      }
      expect(state(env).current, 2);
      expect(state(env).finished, {1});

      // "Xong món 1" không sang món 2 đã xong.
      await viewModel(env).selectDish(0);
      await viewModel(env).next();
      await viewModel(env).next();
      expect(state(env).isLastStep, isTrue);
      await viewModel(env).next();
      final s = state(env);
      expect(s.current, 2);
      expect(s.finished, {0, 1});
      expect(s.unfinished, ['Canh cà chua trứng']);
      expect(s.allFinished, isFalse);
    });

    test('Xong món cuối khi món trước chưa xong: sang món chưa xong, không vào Lưu ý', () async {
      final env = await started();
      await viewModel(env).selectDish(1);
      await viewModel(env).next();
      await viewModel(env).next();
      expect(state(env).isLastStep, isTrue);
      await viewModel(env).next();
      final s = state(env);
      expect((s.inNotes, s.current), (false, 0));
      expect(s.finished, {1});
      expect(s.unfinished, ['Canh cà chua trứng']);
    });

    test('Xong món 1 rồi Xong món 2 thì sang chặng Lưu ý; Bước trước về món đang dở', () async {
      final env = await started();
      for (var i = 0; i < 6; i++) {
        await viewModel(env).next();
      }
      var s = state(env);
      expect((s.inNotes, s.allFinished), (true, true));
      expect(s.finished, {0, 1});
      expect(s.unfinished, isEmpty);
      expect((s.isFirst, s.isLastStep), (false, true));
      expect(env.container.read(cookSessionProvider)!.inNotes, isTrue);
      // "Bước tiếp" không làm gì ở chặng Lưu ý; nút chính là "Xong cả bữa".
      await viewModel(env).next();
      expect(state(env).inNotes, isTrue);

      await viewModel(env).previous();
      s = state(env);
      expect((s.inNotes, s.current, s.index), (false, 1, 2));
    });

    test('tab Lưu ý khi món 1 đang dở: Bước trước về món 1 ở bước đang dở', () async {
      final env = await started();
      await viewModel(env).next();
      await viewModel(env).showNotes();
      var s = state(env);
      expect((s.inNotes, s.inPrep, s.unfinished.length), (true, false, 2));
      // Đồng hồ của bước đang dở không hiện ở chặng Lưu ý khi chưa chạy.
      expect(s.showsTimer(0, 2), isFalse);

      await viewModel(env).previous();
      s = state(env);
      expect((s.inNotes, s.current, s.index), (false, 0, 1));

      // Từ Lưu ý bấm tab món 2 thì mở món 2.
      await viewModel(env).showNotes();
      await viewModel(env).selectDish(0);
      expect((state(env).inNotes, state(env).current), (false, 0));
    });

    test('lưu ý gom theo món, bỏ món không có lưu ý; câu chúc cố định khi chuyển bước', () async {
      final env = await started();
      final s = state(env);
      expect(s.notes.map((n) => n.dish), ['Trứng chiên hành']);
      expect(s.notes.single.notes, ['Ăn nóng với cơm.', 'Chấm thêm nước mắm nếu thích.']);
      expect(s.cheer, CookStrings.cheers[2]);
      await viewModel(env).next();
      await viewModel(env).showNotes();
      expect(state(env).cheer, CookStrings.cheers[2]);
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

    test('đồng hồ của món khác vẫn hiện khi đang chạy; key theo bước gốc của món', () async {
      final env = await started();
      // Bước gốc 2 của canh ("Đổ nước, đun sôi") là bước nấu thứ 2.
      expect(state(env).timedSteps, [(0, 2), (1, 1), (1, 2)]);
      expect(state(env).stepNumber(0, 2), 2);
      await viewModel(env).timerChanged(0, 2, StepTimerStatus.running);
      await viewModel(env).selectDish(1);
      expect(state(env).showsTimer(0, 2), isTrue);
      expect(state(env).showsTimer(1, 2), isFalse);
      expect(state(env).showsTimer(1, 1), isTrue);
      expect(env.notifications.timers.keys, [cookTimerKey(0, 2)]);

      // Chặng Sơ chế: đồng hồ đang chạy vẫn hiện, bước đang xem thì không.
      await viewModel(env).showPrep();
      expect(state(env).showsTimer(0, 2), isTrue);
      expect(state(env).showsTimer(1, 1), isFalse);
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
