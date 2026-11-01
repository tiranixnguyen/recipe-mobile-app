import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/system/presentation/getting_started/getting_started_view_model.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Thẻ "Làm quen với Bếp Hoà Lạc" ở đầu Khám phá: 4 bước, tự tick theo dữ liệu thật. Chưa có
/// prototype nên dựng từ token và component sẵn có. Không hiện khi chưa qua Onboarding hoặc đã ẩn.
///
/// Tự lo khoảng cách bên dưới, nên màn Khám phá cứ đặt `const GettingStartedCard()` trong danh sách.
class GettingStartedCard extends ConsumerWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gettingStartedViewModelProvider);
    if (!state.visible) return const SizedBox.shrink();
    final viewModel = ref.read(gettingStartedViewModelProvider.notifier);
    final colors = context.colors;

    void go(StartRow row) {
      final target = row.target;
      if (target == null) return;
      viewModel.open(row.step);
      target.tab ? context.go(target.location, extra: Object()) : context.push(target.location);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: state.allDone ? colors.herbSoft : colors.surfaceRaised,
          borderRadius: AppRadius.mdAll,
          border: state.allDone ? null : Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: state.allDone
              ? _Done(onClose: viewModel.hide)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(SystemStrings.startTitle, style: AppTextStyles.subtitle),
                        ),
                        AppButton.ghost(label: SystemStrings.startHide, onPressed: viewModel.hide),
                      ],
                    ),
                    Text(
                      SystemStrings.startProgress(state.doneCount, state.total),
                      style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    ClipRRect(
                      borderRadius: AppRadius.pillAll,
                      child: LinearProgressIndicator(
                        value: state.doneCount / state.total,
                        minHeight: 6,
                        backgroundColor: colors.line,
                        color: colors.herb,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    for (final row in state.rows) _Row(row: row, onTap: () => go(row)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.onTap});

  final StartRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = row.done ? colors.inkMuted : colors.ink;
    return Semantics(
      container: true,
      label: row.done ? SystemStrings.startRowDone(row.title) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                row.done ? AppIcons.check : Icons.circle_outlined,
                size: 20,
                color: row.done ? colors.herbInk : colors.inkMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                row.title,
                style: AppTextStyles.body.copyWith(
                  color: textColor,
                  fontWeight: row.next ? FontWeight.w700 : null,
                ),
              ),
            ),
            if (row.next && row.action != null)
              AppButton.ghost(label: row.action!, onPressed: onTap),
          ],
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(AppIcons.check, size: 20, color: colors.herbInk),
            const SizedBox(width: AppSpacing.s2),
            Text(SystemStrings.startDoneTitle, style: AppTextStyles.subtitle),
          ],
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(SystemStrings.startDoneBody, style: AppTextStyles.body.copyWith(color: colors.ink)),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton.ghost(label: SystemStrings.startClose, onPressed: onClose),
        ),
      ],
    );
  }
}
