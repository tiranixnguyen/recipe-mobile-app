import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/system/data/kitchen_profile.dart';
import 'package:recipe_mobile_app/features/system/data/preferences.dart';

/// State của màn Onboarding: dụng cụ và chế độ ăn đang chọn.
class OnboardingState {
  const OnboardingState({this.tools = const {}, this.diets = const {}, this.finishing = false});

  final Set<Tool> tools;
  final Set<Diet> diets;

  /// Đang lưu sau khi bấm Xong / Bỏ qua — View khoá nút để không bấm hai lần.
  final bool finishing;

  OnboardingState copyWith({Set<Tool>? tools, Set<Diet>? diets, bool? finishing}) =>
      OnboardingState(
        tools: tools ?? this.tools,
        diets: diets ?? this.diets,
        finishing: finishing ?? this.finishing,
      );
}

/// Dùng cho cả lần đầu mở app và khi sửa lại từ Cài đặt; bắt đầu từ lựa chọn đã lưu.
class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final profile = ref.read(kitchenProfileProvider);
    return OnboardingState(tools: profile.tools, diets: profile.diets);
  }

  void toggleTool(Tool tool) => state = state.copyWith(tools: _flip(state.tools, tool));

  void toggleDiet(Diet diet) => state = state.copyWith(diets: _flip(state.diets, diet));

  /// Lưu lựa chọn vào [kitchenProfileProvider] và ghi nhận đã qua Onboarding. View tự điều hướng.
  Future<void> save() async {
    state = state.copyWith(finishing: true);
    await ref
        .read(kitchenProfileProvider.notifier)
        .save(KitchenProfile(tools: state.tools, diets: state.diets));
    await _complete(skipped: false);
  }

  /// Bỏ qua: không lưu lựa chọn (hồ sơ bếp để rỗng = chưa chọn), chỉ ghi nhận đã qua Onboarding.
  Future<void> skip() async {
    state = state.copyWith(finishing: true);
    await _complete(skipped: true);
  }

  /// Lần đầu qua Onboarding thì ghi `onboarding_done`; sửa lại từ Cài đặt thì không.
  Future<void> _complete({required bool skipped}) async {
    if (!ref.read(onboardingDoneProvider)) {
      ref.read(analyticsProvider).track('onboarding_done', {
        'skipped': skipped,
        'tools': skipped ? 0 : state.tools.length,
        'diets': skipped ? 0 : state.diets.length,
      });
    }
    await ref.read(onboardingDoneProvider.notifier).complete();
  }

  static Set<T> _flip<T>(Set<T> set, T item) =>
      set.contains(item) ? ({...set}..remove(item)) : {...set, item};
}

final onboardingViewModelProvider =
    NotifierProvider.autoDispose<OnboardingViewModel, OnboardingState>(OnboardingViewModel.new);
