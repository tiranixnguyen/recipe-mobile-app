import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/system/presentation/clear_data/clear_data_view_model.dart';
import 'package:recipe_mobile_app/features/system/system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;
  late ProviderSubscription<ClearDataState> sub;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'system.onboarded': 'true',
      'system.themeMode': 'dark',
    });
    prefs = await SharedPreferences.getInstance();
    // Giống main.dart: mỗi lần dựng lại là một instance mới.
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => SharedPrefsLocalStore(prefs))],
    );
    sub = container.listen(clearDataViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  ClearDataViewModel viewModel() => container.read(clearDataViewModelProvider.notifier);

  test('chưa gõ gì: khoá nút, gợi ý đang khoá', () {
    expect(sub.read().matched, isFalse);
    expect(sub.read().hint, ClearDataHint.locked);
  });

  test('gõ sai hoặc chữ thường: chưa khớp', () {
    viewModel().type('CONFIRM');
    expect(sub.read().matched, isFalse);
    expect(sub.read().hint, ClearDataHint.mismatch);

    viewModel().type('confirm delete');
    expect(sub.read().matched, isFalse);
  });

  test('gõ đúng, bỏ qua khoảng trắng hai đầu: khớp', () {
    viewModel().type('  CONFIRM DELETE ');
    expect(sub.read().matched, isTrue);
    expect(sub.read().hint, ClearDataHint.matched);
  });

  test('chưa khớp thì clear không xoá gì', () async {
    viewModel().type('CONFIRM DELET');
    await viewModel().clear();

    expect(prefs.getString('system.onboarded'), 'true');
    expect(container.read(onboardingDoneProvider), isTrue);
  });

  test('khớp thì clear xoá store và state đọc lại từ store rỗng', () async {
    expect(container.read(themeModeProvider), ThemeMode.dark);

    viewModel().type('CONFIRM DELETE');
    await viewModel().clear();

    expect(prefs.getKeys(), isEmpty);
    expect(container.read(onboardingDoneProvider), isFalse);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
