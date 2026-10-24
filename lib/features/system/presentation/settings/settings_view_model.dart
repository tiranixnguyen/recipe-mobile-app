import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/data/preferences.dart';

/// Mở trang của app trên Google Play. Test override để khỏi gọi platform.
final openStoreListingProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => InAppReview.instance.openStoreListing(),
);

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.timerDone,
    required this.mealReminder,
    this.version,
  });

  final ThemeMode themeMode;
  final bool timerDone;
  final bool mealReminder;

  /// Null khi chưa đọc xong.
  final String? version;
}

class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final notif = ref.watch(notificationPrefsProvider);
    return SettingsState(
      themeMode: ref.watch(themeModeProvider),
      timerDone: notif.timerDone,
      mealReminder: notif.mealReminder,
      version: ref.watch(appVersionProvider).value,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) => ref.read(themeModeProvider.notifier).set(mode);

  // TODO(SYS-03): bật lần đầu thì xin quyền thông báo; bị từ chối thì để tắt.
  Future<void> setTimerDone(bool on) =>
      ref.read(notificationPrefsProvider.notifier).setTimerDone(on);

  Future<void> setMealReminder(bool on) =>
      ref.read(notificationPrefsProvider.notifier).setMealReminder(on);

  Future<void> rateApp() => ref.read(openStoreListingProvider)();
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
