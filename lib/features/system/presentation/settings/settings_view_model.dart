import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/data/notification_permission.dart';
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
    required this.mealReminderLead,
    this.version,
  });

  final ThemeMode themeMode;
  final bool timerDone;
  final bool mealReminder;

  /// Nhắc trước bữa bao lâu.
  final Duration mealReminderLead;

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
      mealReminderLead: notif.mealReminderLead,
      version: ref.watch(appVersionProvider).value,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) return;
    ref.read(analyticsProvider).track('theme_change', {'mode': mode.name});
    await ref.read(themeModeProvider.notifier).set(mode);
  }

  /// Bật thì xin quyền thông báo nếu chưa có; bị từ chối thì để tắt và trả về `false` để View báo.
  Future<bool> setTimerDone(bool on) async {
    if (on && !await _ensurePermission()) return false;
    await ref.read(notificationPrefsProvider.notifier).setTimerDone(on);
    return true;
  }

  /// Như [setTimerDone].
  Future<bool> setMealReminder(bool on) async {
    if (on && !await _ensurePermission()) return false;
    await ref.read(notificationPrefsProvider.notifier).setMealReminder(on);
    return true;
  }

  Future<void> setMealReminderLead(Duration lead) =>
      ref.read(notificationPrefsProvider.notifier).setMealReminderLead(lead);

  Future<bool> _ensurePermission() async {
    final permission = ref.read(notificationPermissionProvider);
    return await permission.isGranted() || await permission.request();
  }

  Future<void> rateApp() => ref.read(openStoreListingProvider)();
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
