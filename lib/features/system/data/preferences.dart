import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _themeModeKey = 'system.themeMode';
const _onboardedKey = 'system.onboarded';

/// Sáng / Tối / Theo hệ thống, chọn trong Cài đặt. Mặc định theo hệ thống.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(localStoreProvider).readString(_themeModeKey);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(localStoreProvider).writeString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Đã qua màn Onboarding (bấm Xong hoặc Bỏ qua) hay chưa; Splash đọc để chọn màn đầu tiên.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(localStoreProvider).readString(_onboardedKey) == 'true';

  Future<void> complete() async {
    state = true;
    await ref.read(localStoreProvider).writeString(_onboardedKey, 'true');
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
