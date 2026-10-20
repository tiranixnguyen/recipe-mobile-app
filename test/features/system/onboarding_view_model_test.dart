import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/presentation/onboarding/onboarding_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  test('finish() khoá nút và ghi nhận đã qua Onboarding', () async {
    final container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(InMemoryLocalStore())],
    );
    addTearDown(container.dispose);
    final sub = container.listen(onboardingViewModelProvider, (_, _) {});

    expect(sub.read().finishing, isFalse);

    await container.read(onboardingViewModelProvider.notifier).finish();

    expect(sub.read().finishing, isTrue);
    expect(container.read(onboardingDoneProvider), isTrue);
  });
}
