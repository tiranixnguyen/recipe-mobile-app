import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/system/presentation/clear_data/clear_data_view_model.dart';
import 'package:recipe_mobile_app/features/system/routes.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Hộp thoại Xoá dữ liệu (prototype `ClearData`), mở đè lên Cài đặt.
///
/// Nút Xoá hết chỉ mở khi gõ đúng [SystemStrings.clearDataPhrase]. Xoá xong về Onboarding: dữ liệu
/// trống nghĩa là chưa qua Onboarding, cũng là màn Splash sẽ chọn.
class ClearDataScreen extends ConsumerWidget {
  const ClearDataScreen({super.key});

  /// Từ cỡ chữ này (cài đặt máy) hai nút nằm chồng, để nhãn không bị bẻ đôi.
  static const _stackButtonsTextScale = 1.15;

  static const _mono = TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(clearDataViewModelProvider);
    final viewModel = ref.read(clearDataViewModelProvider.notifier);

    Future<void> clear() async {
      // Lấy router trước khi await: xoá xong thì màn này có thể đã bị gỡ khỏi cây.
      final router = GoRouter.of(context);
      await viewModel.clear();
      router.go(onboardingLocation);
    }

    final (hint, hintColor) = switch (state.hint) {
      ClearDataHint.locked => (SystemStrings.clearDataLocked, colors.inkMuted),
      ClearDataHint.mismatch => (SystemStrings.clearDataMismatch, colors.inkMuted),
      ClearDataHint.matched => (SystemStrings.clearDataMatched, colors.herbInk),
    };
    final cancelButton = AppButton.secondary(
      label: SystemStrings.cancel,
      block: true,
      onPressed: state.clearing ? null : () => context.pop(),
    );
    final deleteButton = AppButton.danger(
      label: SystemStrings.clearDataConfirm,
      icon: AppIcons.trash,
      block: true,
      onPressed: state.matched && !state.clearing ? clear : null,
    );

    return PopScope(
      // Đang xoá thì không cho đóng (back, chạm ra ngoài), để xoá xong còn về Onboarding.
      canPop: !state.clearing,
      child: Dialog(
        backgroundColor: colors.surfaceRaised,
        insetPadding: const EdgeInsets.all(AppSpacing.s5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s6,
            AppSpacing.s5,
            AppSpacing.s5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: colors.chiliSoft, shape: BoxShape.circle),
                    child: Icon(AppIcons.trash, color: colors.dangerInk),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(SystemStrings.clearDataTitle, style: AppTextStyles.title),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              const Text(SystemStrings.clearDataIntro, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.s2),
              for (final item in SystemStrings.clearDataItems)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s2, bottom: 2),
                  // Dòng xuống thẳng hàng với chữ, không lùi về dưới dấu chấm.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: AppTextStyles.body),
                      Expanded(child: Text(item, style: AppTextStyles.body)),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                SystemStrings.clearDataWarning,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.dangerInk,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: SystemStrings.clearDataPrompt.$1),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.chiliSoft,
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                        ),
                        child: Text(
                          SystemStrings.clearDataPhrase,
                          style: AppTextStyles.label.merge(_mono).copyWith(color: colors.chiliDeep),
                        ),
                      ),
                    ),
                    TextSpan(text: SystemStrings.clearDataPrompt.$2),
                  ],
                ),
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 6),
              TextField(
                onChanged: viewModel.type,
                enabled: !state.clearing,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.body.merge(_mono).copyWith(letterSpacing: 0.6),
                decoration: InputDecoration(
                  hintText: SystemStrings.clearDataPhrase,
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: _border(colors.outline, 1),
                  enabledBorder: state.matched
                      ? _border(colors.herb, 2)
                      : _border(colors.outline, 1),
                  focusedBorder: state.matched ? _border(colors.herb, 2) : _border(colors.chili, 2),
                  disabledBorder: _border(colors.herb, 2),
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                liveRegion: true,
                child: Text(
                  hint,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hintColor,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              if (MediaQuery.textScalerOf(context).scale(1) > _stackButtonsTextScale)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    deleteButton,
                    const SizedBox(height: AppSpacing.s2),
                    cancelButton,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(child: deleteButton),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: AppRadius.mdAll,
    borderSide: BorderSide(color: color, width: width),
  );
}
