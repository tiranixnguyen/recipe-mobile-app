import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';

/// Sheet hỏi lại khi bấm nút chuyển chặng mà việc trước chưa xong ("Chưa lấy đủ đồ", "Chưa sơ chế
/// xong", "Còn món chưa xong"). [confirmLabel] là nút chính; [cancelLabel] hoặc vuốt đóng thì ở lại.
///
/// Trả true khi người dùng vẫn muốn đi tiếp.
Future<bool> showCookConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final colors = context.colors;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s2,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: AppTextStyles.subtitle.copyWith(color: colors.ink)),
            ),
            Text(body, style: AppTextStyles.body.copyWith(color: colors.inkMuted)),
            const SizedBox(height: AppSpacing.s2),
            AppButton(
              label: confirmLabel,
              size: AppButtonSize.lg,
              block: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            AppButton.secondary(
              label: cancelLabel,
              size: AppButtonSize.lg,
              block: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}
