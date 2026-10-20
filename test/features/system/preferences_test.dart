import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  late InMemoryLocalStore store;
  late ProviderContainer container;

  setUp(() {
    store = InMemoryLocalStore();
    container = ProviderContainer(overrides: [localStoreProvider.overrideWithValue(store)]);
  });

  tearDown(() => container.dispose());

  test('theme mặc định theo hệ thống, đổi thì lưu lại', () async {
    expect(container.read(themeModeProvider), ThemeMode.system);

    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(store.readString('system.themeMode'), 'dark');
  });

  test('onboarding chưa xong cho tới khi complete()', () async {
    expect(container.read(onboardingDoneProvider), isFalse);

    await container.read(onboardingDoneProvider.notifier).complete();

    expect(container.read(onboardingDoneProvider), isTrue);
    expect(store.readString('system.onboarded'), 'true');
  });
}
