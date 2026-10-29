import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/pantry/domain/pantry_list.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_view_model.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

import '../../core/fake_analytics.dart';

const _egg = Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein);
const _tofu = Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein);
const _rice = Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch);
const _ingredients = [
  _egg,
  _tofu,
  _rice,
  Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
];

void main() {
  late ProviderContainer container;
  late FakeAnalytics analytics;
  late ProviderSubscription<AsyncValue<PantryState>> sub;

  setUp(() {
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) async => _ingredients),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    sub = container.listen(pantryViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  PantryViewModel viewModel() => container.read(pantryViewModelProvider.notifier);
  PantryState state() => sub.read().requireValue;
  List<ShoppingItem> shopping() => container.read(shoppingItemsProvider);

  Future<PantryState> loaded() async {
    await container.read(ingredientsProvider.future);
    return state();
  }

  test('ban đầu: nhóm theo prototype, đếm 0, chưa tìm', () async {
    final s = await loaded();
    expect(s.groups.map((g) => g.key), [
      PantryGroupKey.starch,
      PantryGroupKey.protein,
      PantryGroupKey.vegetable,
    ]);
    expect(s.summary, (have: 0, needed: 0));
    expect(s.counts, (have: 0, needed: 0));
    expect(s.shoppingCount, 0);
    expect(s.noResult, isFalse);
  });

  test('bấm chip: chưa có → có → chưa có, lưu LocalStore, ghi pantry_update', () async {
    await loaded();
    await viewModel().tap('egg');
    expect(state().statusOf('egg'), ChipStatus.have);
    expect(container.read(localStoreProvider).readList('pantry.items'), ['egg']);
    expect(state().summary, (have: 1, needed: 0));

    await viewModel().tap('egg');
    expect(state().statusOf('egg'), ChipStatus.none);
    expect(container.read(pantryItemsProvider), isEmpty);
    expect(analytics.events, ['pantry_update', 'pantry_update']);
    expect(analytics.params, [
      {'action': 'add'},
      {'action': 'remove'},
    ]);
  });

  test('bấm chip đang cần mua = đã mua: vào tủ, ra khỏi đi chợ', () async {
    await loaded();
    await viewModel().addToShopping(_egg);
    expect(state().statusOf('egg'), ChipStatus.needed);

    await viewModel().tap('egg');
    expect(state().statusOf('egg'), ChipStatus.have);
    expect(shopping(), isEmpty);
    expect(analytics.params.last, {'action': 'bought'});
  });

  test('kéo vào đi chợ: thêm, badge tăng, ẩn mẹo, ghi analytics via drag', () async {
    await loaded();
    final outcome = await viewModel().addToShopping(_egg);

    expect(outcome.result, PantryShopResult.added);
    expect(outcome.name, 'Trứng gà');
    expect(shopping(), [const ShoppingItem.ingredient('egg')]);
    expect(state().shoppingCount, 1);
    expect(state().counts, (have: 0, needed: 1));
    expect(state().summary, (have: 0, needed: 1));
    expect(container.read(tipsSeenProvider), contains(pantryDragTip));
    expect(analytics.events, ['add_to_shopping_from_pantry']);
    expect(analytics.params.single, {'via': 'drag'});
  });

  test('kéo đồ đã có trong đi chợ thì báo trùng, không thêm', () async {
    await loaded();
    await viewModel().addToShopping(_egg);
    final outcome = await viewModel().addToShopping(_egg);

    expect(outcome.result, PantryShopResult.alreadyThere);
    expect(shopping(), hasLength(1));
    expect(analytics.events, ['add_to_shopping_from_pantry']);
  });

  test('kéo đồ đang có trong tủ thì không thêm, mẹo vẫn còn', () async {
    await loaded();
    await viewModel().tap('egg');
    final outcome = await viewModel().addToShopping(_egg);

    expect(outcome.result, PantryShopResult.inPantry);
    expect(shopping(), isEmpty);
    expect(container.read(tipsSeenProvider), isEmpty);
  });

  test('hoàn tác bỏ đúng thứ vừa thêm', () async {
    await loaded();
    await viewModel().addToShopping(_tofu);
    final outcome = await viewModel().addToShopping(_egg);
    await viewModel().undoAdd(outcome.item);

    expect(shopping(), [const ShoppingItem.ingredient('tofu')]);
    expect(state().statusOf('egg'), ChipStatus.none);
  });

  test('tìm bỏ dấu, khớp tên nhóm; không thấy thì thêm từ khoá vào đi chợ', () async {
    await loaded();
    viewModel().setQuery('dau');
    expect(state().groups.single.items, [_tofu]);

    viewModel().setQuery('tinh bot');
    expect(state().groups.single.items, [_rice]);

    viewModel().setQuery('  Nước mắm ');
    expect(state().noResult, isTrue);
    final outcome = await viewModel().addQueryToShopping();

    expect(outcome?.result, PantryShopResult.added);
    expect(outcome?.name, 'Nước mắm');
    expect(state().query, isEmpty);
    expect(shopping(), [const ShoppingItem.custom('Nước mắm')]);
    expect(state().summary, (have: 0, needed: 1));
    expect(state().counts, (have: 0, needed: 0));
    expect(analytics.params.single, {'via': 'search'});

    viewModel().setQuery('nuoc mam');
    expect((await viewModel().addQueryToShopping())?.result, PantryShopResult.alreadyThere);
    expect(shopping(), hasLength(1));

    expect(await viewModel().addQueryToShopping(), isNull);
  });

  test('bộ lọc và mở/đóng nhóm; đang tìm thì nhóm luôn mở', () async {
    await loaded();
    await viewModel().tap('egg');
    await viewModel().addToShopping(_rice);

    viewModel().setFilter(PantryFilter.have);
    expect(state().groups.expand((g) => g.items), [_egg]);
    viewModel().setFilter(PantryFilter.needed);
    expect(state().groups.expand((g) => g.items), [_rice]);
    viewModel().setFilter(PantryFilter.all);

    viewModel().toggleGroup(PantryGroupKey.protein);
    expect(state().isCollapsed(PantryGroupKey.protein), isTrue);
    viewModel().setQuery('trung');
    expect(state().isCollapsed(PantryGroupKey.protein), isFalse);
    viewModel().clearQuery();
    expect(state().isCollapsed(PantryGroupKey.protein), isTrue);
    viewModel().toggleGroup(PantryGroupKey.protein);
    expect(state().isCollapsed(PantryGroupKey.protein), isFalse);
  });

  test('dữ liệu lỗi thì state lỗi', () async {
    final failing = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) => Future.error(const FormatException('hỏng'))),
      ],
    );
    addTearDown(failing.dispose);
    final failingSub = failing.listen(pantryViewModelProvider, (_, _) {});
    await expectLater(failing.read(ingredientsProvider.future), throwsFormatException);

    expect(failingSub.read().hasError, isTrue);
  });
}
