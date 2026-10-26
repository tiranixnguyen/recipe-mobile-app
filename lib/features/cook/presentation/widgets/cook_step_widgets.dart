import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Đầu màn Từng bước: nút thoát, "Bước x/y", nút "Nguyên liệu"; thanh đoạn tiến độ và dòng "Màn
/// hình luôn sáng". [below] đặt dưới hàng nút (tab món khi nấu cả bữa, khi đó [showProgress] false
/// vì mỗi tab có tiến độ riêng).
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.done,
    required this.onClose,
    required this.onIngredients,
    this.title,
    this.below,
    this.showProgress = true,
  });

  final int step;
  final int total;

  /// Số đoạn tô `chili` (bước đã qua và bước đang xem).
  final int done;
  final VoidCallback onClose;
  final VoidCallback onIngredients;

  /// Chữ giữa hàng nút; mặc định "Bước x/y".
  final String? title;
  final Widget? below;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final below = this.below;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s1, AppSpacing.s2, AppSpacing.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s2,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                tooltip: CookStrings.exitCooking,
                icon: Icon(AppIcons.close, color: colors.ink),
                style: IconButton.styleFrom(minimumSize: const Size.square(48)),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title ?? CookStrings.stepOf(step, total),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
              // Chữ to thì nút chia chỗ với tiêu đề, không ép tiêu đề xuống từng chữ một dòng.
              Flexible(
                child: AppButton.ghost(
                  label: CookStrings.ingredients,
                  icon: AppIcons.list,
                  onPressed: onIngredients,
                ),
              ),
            ],
          ),
          ?below,
          if (showProgress) ...[
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s3),
              child: ExcludeSemantics(
                child: Row(
                  spacing: AppSpacing.s1,
                  children: [
                    for (var i = 0; i < total; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < done ? colors.chili : colors.line,
                            borderRadius: AppRadius.pillAll,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s3),
              child: Text(
                CookStrings.keepScreenOn,
                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Phần giữa màn Từng bước: nhãn "BƯỚC n", chữ bước 24/34, đồng hồ sát footer. Màn thấp hoặc chữ
/// to thì cả phần này cuộn, để header và footer luôn hiện.
class StepBody extends StatelessWidget {
  const StepBody({super.key, required this.label, required this.text, required this.timers});

  final String label;
  final String text;
  final StepTimers timers;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s6,
            AppSpacing.s8,
            AppSpacing.s6,
            AppSpacing.s4,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s5,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 13 * 0.04,
                    color: colors.chiliDeep,
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(text, style: AppTextStyles.step.copyWith(color: colors.ink)),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(alignment: Alignment.bottomCenter, child: timers),
        ),
      ],
    );
  }
}

/// Khu hẹn giờ trên footer: mọi đồng hồ luôn mounted để chạy tiếp khi sang bước (món) khác.
class StepTimers extends StatelessWidget {
  const StepTimers({super.key, required this.timers});

  final List<StepTimerSlot> timers;

  @override
  Widget build(BuildContext context) {
    if (timers.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: CookStrings.timers,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: timers,
        ),
      ),
    );
  }
}

/// Một `StepTimer`; ẩn ([visible] false) vẫn giữ trạng thái và tiếp tục đếm.
class StepTimerSlot extends StatelessWidget {
  const StepTimerSlot({
    super.key,
    required this.visible,
    required this.seconds,
    this.endAt,
    required this.label,
    required this.clock,
    required this.onStatusChange,
  });

  final bool visible;
  final int seconds;

  /// Mốc hết giờ đã lưu khi mở lại màn lúc đồng hồ còn chạy.
  final DateTime? endAt;
  final String label;
  final DateTime Function() clock;
  final ValueChanged<StepTimerStatus> onStatusChange;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !visible,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s2),
        child: StepTimer(
          seconds: seconds,
          endAt: endAt,
          label: label,
          clock: clock,
          onStatusChange: onStatusChange,
          // Đang mở app thì rung; ở app khác thì thông báo đã hẹn lo.
          onDone: HapticFeedback.vibrate,
        ),
      ),
    );
  }
}

/// Sheet "Nguyên liệu · n người" ([title] thay tiêu đề khi nấu cả bữa): tên — lượng theo khẩu
/// phần, gia vị cơ bản "Vừa đủ".
Future<void> showStepIngredients(
  BuildContext context, {
  String? title,
  required int servings,
  required List<StepIngredient> items,
  required List<String> basicSpices,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final colors = context.colors;
    final rows = [
      for (final item in items) (item.name, item.amountText),
      if (basicSpices.isNotEmpty) (basicSpices.join(', '), CookStrings.enough),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s3,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title ?? CookStrings.sheetTitle(servings),
                    style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                  ),
                ),
              ),
              AppButton.ghost(
                label: CookStrings.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Column(
            children: [
              for (final (i, (name, amount)) in rows.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.s3,
                    children: [
                      Expanded(
                        child: Text(name, style: AppTextStyles.body.copyWith(color: colors.ink)),
                      ),
                      Text(
                        amount,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  },
);
