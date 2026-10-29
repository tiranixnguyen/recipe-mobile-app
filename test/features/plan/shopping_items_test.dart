import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
    );
  });

  tearDown(() => container.dispose());

  ShoppingItemsController items() => container.read(shoppingItemsProvider.notifier);

  test('mặc định rỗng, badge 0', () {
    expect(container.read(shoppingItemsProvider), isEmpty);
    expect(container.read(shoppingCountProvider), 0);
  });

  test('thêm nguyên liệu và tên tự gõ theo thứ tự, lưu lại được', () async {
    expect(await items().addIngredient('egg'), AddToShoppingResult.added);
    expect(await items().addCustom('  Nước mắm '), AddToShoppingResult.added);

    const expected = [ShoppingItem.ingredient('egg'), ShoppingItem.custom('Nước mắm')];
    expect(container.read(shoppingItemsProvider), expected);
    expect(container.read(shoppingCountProvider), 2);

    container.invalidate(shoppingItemsProvider);
    expect(container.read(shoppingItemsProvider), expected);
  });

  test('trùng thì không thêm lần nữa', () async {
    await items().addIngredient('egg');
    expect(await items().addIngredient('egg'), AddToShoppingResult.alreadyThere);
    expect(container.read(shoppingItemsProvider), [const ShoppingItem.ingredient('egg')]);
  });

  test('tên tự gõ trùng khi bỏ dấu và chữ hoa', () async {
    await items().addCustom('Nước mắm');
    expect(await items().addCustom('NUOC MAM'), AddToShoppingResult.alreadyThere);
    expect(await items().addCustom('nước mắm '), AddToShoppingResult.alreadyThere);
    expect(container.read(shoppingCountProvider), 1);
  });

  test('remove bỏ đúng thứ đó, không có thì thôi', () async {
    await items().addIngredient('egg');
    await items().addCustom('Gừng');
    await items().remove(const ShoppingItem.ingredient('egg'));
    await items().remove(const ShoppingItem.ingredient('rice'));
    expect(container.read(shoppingItemsProvider), [const ShoppingItem.custom('Gừng')]);
  });

  test('dữ liệu hỏng thì bỏ bản ghi hỏng hoặc cả danh sách', () async {
    final store = container.read(localStoreProvider);
    await store.writeString(
      'plan.shoppingItems',
      '[{"ingredientId":"egg"},{"name":"  "},{"ingredientId":3},{},"x",{"name":"Gừng"}]',
    );
    container.invalidate(shoppingItemsProvider);
    expect(container.read(shoppingItemsProvider), [
      const ShoppingItem.ingredient('egg'),
      const ShoppingItem.custom('Gừng'),
    ]);

    await store.writeString('plan.shoppingItems', '{không phải json');
    container.invalidate(shoppingItemsProvider);
    expect(container.read(shoppingItemsProvider), isEmpty);
  });
}
