import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences.dart';

/// State của màn Onboarding. SYS-01 thêm dụng cụ và chế độ ăn đang chọn (enum `Tool`, `Diet`).
class OnboardingState {
  const OnboardingState({this.finishing = false});

  /// Đang lưu sau khi bấm Xong / Bỏ qua — View khoá nút để không bấm hai lần.
  final bool finishing;
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  /// Ghi nhận đã qua Onboarding. View tự điều hướng sau khi xong.
  Future<void> finish() async {
    state = const OnboardingState(finishing: true);
    await ref.read(onboardingDoneProvider.notifier).complete();
  }
}

final onboardingViewModelProvider =
    NotifierProvider.autoDispose<OnboardingViewModel, OnboardingState>(OnboardingViewModel.new);
