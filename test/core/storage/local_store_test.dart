import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

void main() {
  test('clearLocalData xoá store và dựng lại state đang watch', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Giống main.dart: mỗi lần dựng lại là một instance mới.
    final container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => SharedPrefsLocalStore(prefs))],
    );
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await container.read(onboardingDoneProvider.notifier).complete();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(container.read(onboardingDoneProvider), isTrue);

    await container.read(clearLocalDataProvider)();

    expect(prefs.getKeys(), isEmpty);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(container.read(onboardingDoneProvider), isFalse);
  });
}
