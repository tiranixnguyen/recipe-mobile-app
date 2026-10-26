import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/presentation/done/done_view_model.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import 'fakes.dart';
import 'fixtures.dart';

class _Env {
  _Env() {
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
        ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
        cookClockProvider.overrideWithValue(() => now),
        appReviewProvider.overrideWithValue(review),
      ],
    );
    addTearDown(container.dispose);
  }

  late final ProviderContainer container;
  final review = FakeAppReview();
  var now = DateTime(2026, 10, 26, 19);

  final provider = doneViewModelProvider('trung');
  DoneViewModel get viewModel => container.read(provider.notifier);
  DoneState get state => container.read(provider).requireValue;

  Future<void> open() async {
    container.listen(provider, (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
  }

  Future<void> addToPantry(List<String> ids) async {
    for (final id in ids) {
      await container.read(pantryItemsProvider.notifier).addToPantry(id);
    }
  }
}

void main() {
  test('khẩu phần theo phiên nấu, đồ đã dùng theo khẩu phần, mặc định không tick', () async {
    final env = _Env();
    await env.addToPantry(['egg', 'scallion']);
    await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 2);
    await env.open();

    expect(env.state.servings, 2);
    expect(env.state.used.map((u) => u.note), ['Đã dùng 4 quả', 'Đã dùng 2 nắm']);
    expect(env.state.usedUp, isEmpty);
    expect(env.state.rating, isNull);
  });

  test('Cập nhật tủ và xong: bỏ đồ đã tick, ghi lịch sử kèm đánh giá, xoá phiên', () async {
    final env = _Env();
    await env.addToPantry(['egg', 'scallion']);
    await env.container.read(cookSessionProvider.notifier).startRecipe('trung', 1);
    await env.open();

    env.viewModel.toggleUsedUp('scallion');
    env.viewModel.toggleUsedUp('egg');
    env.viewModel.toggleUsedUp('egg');
    env.viewModel.rate(CookRating.bad);
    await env.viewModel.finish();

    expect(env.container.read(pantryItemsProvider), {'egg'});
    expect(env.container.read(cookHistoryProvider), [
      CookRecord(recipeId: 'trung', cookedAt: env.now, rating: CookRating.bad),
    ]);
    expect(env.container.read(cookSessionProvider), isNull);
    expect(env.review.requests, 0);
  });

  test('chọn lại đánh giá đang chọn thì bỏ; không đánh giá vẫn ghi lịch sử', () async {
    final env = _Env();
    await env.open();
    env.viewModel.rate(CookRating.good);
    env.viewModel.rate(CookRating.good);
    expect(env.state.rating, isNull);

    await env.viewModel.finish();
    expect(env.container.read(cookHistoryProvider).single.rating, isNull);
  });

  test('Lưu món để nấu lại bật / tắt món đã lưu', () async {
    final env = _Env();
    await env.open();
    await env.viewModel.toggleSaved();
    expect(env.state.saved, isTrue);
    expect(env.container.read(savedIdsProvider), {'trung'});
  });

  test('hỏi đánh giá app khi đủ 3 lần Ngon, không hỏi lại trong 90 ngày', () async {
    final env = _Env();
    final history = env.container.read(cookHistoryProvider.notifier);
    await history.record('a', rating: CookRating.good);
    await env.open();

    Future<void> cookGood() async {
      // Màn giữ đánh giá đã chọn; bấm lại cái đang chọn là bỏ chọn.
      if (env.state.rating != CookRating.good) env.viewModel.rate(CookRating.good);
      await env.viewModel.finish();
    }

    await cookGood();
    expect(env.review.requests, 0);
    await cookGood();
    expect(env.review.requests, 1);
    await cookGood();
    expect(env.review.requests, 1);

    env.now = env.now.add(ReviewPrompt.askAgainAfter);
    await cookGood();
    expect(env.review.requests, 2);
  });
}
