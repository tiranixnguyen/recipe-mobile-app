import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/prep/prep_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import '../system/fake_notification_plugin.dart';
import 'fixtures.dart';

ProviderContainer _container({FakeNotificationPlugin? plugin}) {
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
      ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
      notificationPluginProvider.overrideWithValue(plugin ?? FakeNotificationPlugin()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<PrepState> _read(ProviderContainer container, [String id = 'trung']) async {
  final provider = prepViewModelProvider(id);
  container.listen(provider, (_, _) {});
  await container.read(recipesProvider.future);
  await container.read(ingredientsProvider.future);
  return container.read(provider).requireValue;
}

void main() {
  test('khẩu phần mặc định của món; đổi thì lượng đổi, giữ dòng đã tick', () async {
    final container = _container();
    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    var state = await _read(container);
    expect(state.servings, 1);
    expect(state.gather.single.label, 'Trứng gà · 2 quả');
    expect((state.checkedCount, state.total), (0, 2));

    final viewModel = container.read(prepViewModelProvider('trung').notifier);
    viewModel.toggle('egg');
    viewModel.setServings(3);
    state = container.read(prepViewModelProvider('trung')).requireValue;
    expect(state.servings, 3);
    expect(state.gather.single.label, 'Trứng gà · 6 quả');
    expect((state.checkedCount, state.total), (1, 2));

    viewModel.toggle(PrepViewModel.spicesKey);
    viewModel.toggle('egg');
    state = container.read(prepViewModelProvider('trung')).requireValue;
    expect(state.checked, {PrepViewModel.spicesKey});
  });

  test('khẩu phần giữ trong 1–6', () async {
    final container = _container();
    await _read(container);
    final viewModel = container.read(prepViewModelProvider('trung').notifier);
    viewModel.setServings(9);
    expect(container.read(prepViewModelProvider('trung')).requireValue.servings, 6);
    viewModel.setServings(0);
    expect(container.read(prepViewModelProvider('trung')).requireValue.servings, 1);
  });

  test('đồ thiếu kèm ghi chú; thêm đồ vào tủ thì hết thiếu', () async {
    final container = _container();
    var state = await _read(container);
    expect(state.missing.map((m) => m.name), ['trứng gà', 'hành lá', 'ớt']);
    expect(state.notes, ['Không có cũng được, hoặc thay bằng chút ớt bột.']);

    for (final id in ['egg', 'scallion', 'chili']) {
      await container.read(pantryItemsProvider.notifier).addToPantry(id);
    }
    state = container.read(prepViewModelProvider('trung')).requireValue;
    expect(state.missing, isEmpty);
    expect(state.gather, hasLength(3));
  });

  test('Thêm vào đi chợ cả món với khẩu phần đang chọn', () async {
    final container = _container();
    await _read(container);
    final viewModel = container.read(prepViewModelProvider('trung').notifier);
    viewModel.setServings(2);
    await viewModel.addToShopping();
    expect(container.read(shoppingProvider), [
      const ShoppingRequest(recipeId: 'trung', servings: 2),
    ]);
  });

  test('Bắt đầu nấu mở phiên nấu mới với khẩu phần đang chọn', () async {
    final container = _container();
    await _read(container);
    final viewModel = container.read(prepViewModelProvider('trung').notifier);
    viewModel.setServings(2);
    await viewModel.start();
    final session = container.read(cookSessionProvider)!;
    expect(session.currentDish, (recipeId: 'trung', servings: 2));
    expect(session.positions, [0]);
  });

  test('món có hẹn giờ mà chưa có quyền thông báo thì hỏi quyền trước', () async {
    final denied = _container(plugin: FakeNotificationPlugin(permitted: false));
    await _read(denied);
    expect(
      await denied.read(prepViewModelProvider('trung').notifier).shouldAskNotificationPermission(),
      isTrue,
    );

    final granted = _container();
    await _read(granted);
    expect(
      await granted.read(prepViewModelProvider('trung').notifier).shouldAskNotificationPermission(),
      isFalse,
    );
  });

  test('id không có thì lỗi RecipeNotFound', () async {
    final container = _container();
    final provider = prepViewModelProvider('khong-co');
    container.listen(provider, (_, _) {});
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    expect(container.read(provider).error, isA<RecipeNotFound>());
  });
}
