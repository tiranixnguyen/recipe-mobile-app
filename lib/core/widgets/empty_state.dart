import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Trạng thái trống (component `EmptyState`): chưa lưu món, tìm không ra, tủ đồ trống, thực đơn trống.
///
/// Vòng tròn `chiliSoft` có icon, tiêu đề, một câu `inkMuted` chỉ cách thoát ra ("Thử bỏ bớt bộ
/// lọc", không "Không có kết quả"), và tối đa một nút phụ ([actionLabel] + [onAction]).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.bowl,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = this.message;
    final actionLabel = this.actionLabel;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              margin: const EdgeInsets.only(bottom: AppSpacing.s4),
              decoration: BoxDecoration(color: colors.chiliSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: colors.chili),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(color: colors.ink),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: colors.inkMuted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppButton.secondary(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
