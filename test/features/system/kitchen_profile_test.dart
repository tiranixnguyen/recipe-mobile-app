import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
    );
  });

  tearDown(() => container.dispose());

  LocalStore store() => container.read(localStoreProvider);

  test('mặc định rỗng (chưa chọn)', () {
    expect(container.read(kitchenProfileProvider), const KitchenProfile());
  });

  test('save lưu lại và đọc được sau khi dựng lại', () async {
    const profile = KitchenProfile(tools: {Tool.rice, Tool.kettle}, diets: {Diet.veg});

    await container.read(kitchenProfileProvider.notifier).save(profile);

    expect(container.read(kitchenProfileProvider), profile);
    expect(store().readList('system.tools'), unorderedEquals(['rice', 'kettle']));
    expect(store().readList('system.diets'), ['veg']);

    container.invalidate(kitchenProfileProvider);
    expect(container.read(kitchenProfileProvider), profile);
  });

  test('id lạ trong store bị bỏ qua', () async {
    await store().writeList('system.tools', ['stove', 'oven']);
    await store().writeList('system.diets', ['keto', 'nopork']);
    container.invalidate(kitchenProfileProvider);

    expect(
      container.read(kitchenProfileProvider),
      const KitchenProfile(tools: {Tool.stove}, diets: {Diet.nopork}),
    );
  });

  test('xoá dữ liệu đưa về rỗng', () async {
    await container
        .read(kitchenProfileProvider.notifier)
        .save(const KitchenProfile(tools: {Tool.micro}, diets: {Diet.light}));

    await container.read(clearLocalDataProvider)();

    expect(container.read(kitchenProfileProvider), const KitchenProfile());
  });

  test('copyWith chỉ đổi phần truyền vào', () {
    const profile = KitchenProfile(tools: {Tool.rice}, diets: {Diet.veg});
    expect(
      profile.copyWith(diets: {}),
      const KitchenProfile(tools: {Tool.rice}),
    );
  });
}
