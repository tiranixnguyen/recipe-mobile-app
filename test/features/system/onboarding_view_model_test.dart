import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import '../../core/fake_analytics.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<OnboardingState> sub;
  late FakeAnalytics analytics;

  setUp(() {
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        analyticsProvider.overrideWithValue(analytics),
      ],
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

  test('lần đầu Xong hay Bỏ qua đều ghi onboarding_done', () async {
    viewModel()
      ..toggleTool(Tool.kettle)
      ..toggleTool(Tool.rice)
      ..toggleDiet(Diet.veg);
    await viewModel().save();

    expect(analytics.events, ['onboarding_done']);
    expect(analytics.params.single, {'skipped': false, 'tools': 2, 'diets': 1});
  });

  test('Bỏ qua ghi onboarding_done với skipped', () async {
    viewModel().toggleTool(Tool.micro);
    await viewModel().skip();

    expect(analytics.events, ['onboarding_done']);
    expect(analytics.params.single, {'skipped': true, 'tools': 0, 'diets': 0});
  });

  test('sửa lại từ Cài đặt thì không ghi onboarding_done nữa', () async {
    await container.read(onboardingDoneProvider.notifier).complete();

    await viewModel().save();

    expect(analytics.events, isEmpty);
  });
}
