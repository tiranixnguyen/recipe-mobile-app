import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<OnboardingState> sub;

  setUp(() {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(InMemoryLocalStore())],
    );
    sub = container.listen(onboardingViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  OnboardingViewModel viewModel() => container.read(onboardingViewModelProvider.notifier);

  test('lần đầu chưa chọn gì', () {
    expect(sub.read().tools, isEmpty);
    expect(sub.read().diets, isEmpty);
    expect(sub.read().finishing, isFalse);
  });

  test('bấm lại thì bỏ chọn', () {
    viewModel()
      ..toggleTool(Tool.rice)
      ..toggleTool(Tool.stove)
      ..toggleTool(Tool.rice)
      ..toggleDiet(Diet.nospicy);

    expect(sub.read().tools, {Tool.stove});
    expect(sub.read().diets, {Diet.nospicy});
  });

  test('save() lưu hồ sơ bếp, khoá nút và ghi nhận đã qua Onboarding', () async {
    viewModel()
      ..toggleTool(Tool.kettle)
      ..toggleDiet(Diet.veg);

    await viewModel().save();

    expect(sub.read().finishing, isTrue);
    expect(container.read(onboardingDoneProvider), isTrue);
    expect(
      container.read(kitchenProfileProvider),
      const KitchenProfile(tools: {Tool.kettle}, diets: {Diet.veg}),
    );
  });

  test('skip() không lưu lựa chọn, chỉ ghi nhận đã qua Onboarding', () async {
    viewModel().toggleTool(Tool.micro);

    await viewModel().skip();

    expect(sub.read().finishing, isTrue);
    expect(container.read(onboardingDoneProvider), isTrue);
    expect(container.read(kitchenProfileProvider), const KitchenProfile());
  });

  test('mở lại (sửa từ Cài đặt) bắt đầu từ lựa chọn đã lưu', () async {
    await container
        .read(kitchenProfileProvider.notifier)
        .save(const KitchenProfile(tools: {Tool.rice}, diets: {Diet.light}));
    sub.close();
    container.invalidate(onboardingViewModelProvider);

    final state = container.read(onboardingViewModelProvider);
    expect(state.tools, {Tool.rice});
    expect(state.diets, {Diet.light});
  });
}
