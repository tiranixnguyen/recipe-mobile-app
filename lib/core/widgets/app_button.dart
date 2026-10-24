import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';

enum AppButtonVariant {
  /// Nền `chili`, chữ trắng — chỉ **một** nút mỗi màn, cho việc chính của màn đó.
  primary,

  /// Nền `surfaceRaised`, viền `outline`, chữ `ink`.
  secondary,

  /// Không nền, chữ `chiliDeep` — hành động phụ như "Bỏ qua".
  ghost,

  /// Nền `danger`, chữ trắng — chỉ cho hành động không hoàn tác được ("Xoá hết"); để disabled tới
  /// khi người dùng xác nhận.
  danger,
}

enum AppButtonSize {
  /// Cao 48, chữ 15/22.
  md,

  /// Cao 56, chữ 17/24 — nút điều hướng ở chế độ nấu ("Bước tiếp", "Bắt đầu nấu").
  lg,
}

/// Nút bấm theo component `Button`.
///
/// Nhãn bắt đầu bằng động từ, viết hoa chữ đầu ("Thêm vào danh sách đi chợ"). [onPressed] null thì
/// nút mờ đi và không bấm được. [block] cho nút chiếm hết chiều ngang ở cuối màn.
///
/// ```dart
/// AppButton(label: 'Bắt đầu nấu', size: AppButtonSize.lg, block: true, onPressed: …)
/// AppButton.secondary(label: 'Hẹn 3 phút', icon: AppIcons.timer, onPressed: …)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.block = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.block = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.block = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.icon,
    this.block = false,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Icon trước nhãn, lấy từ `AppIcons`.
  final IconData? icon;
  final bool block;

  /// Độ mờ khi disabled, như `opacity: .45` trong design.
  static const disabledOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Chữ trắng trên nền `chili`/`danger` như design (5.2:1 và 6.6:1).
    final (Color background, Color foreground, Color? border) = switch (variant) {
      AppButtonVariant.primary => (colors.chili, Colors.white, null),
      AppButtonVariant.secondary => (colors.surfaceRaised, colors.ink, colors.outline),
      AppButtonVariant.ghost => (Colors.transparent, colors.chiliDeep, null),
      AppButtonVariant.danger => (colors.danger, Colors.white, null),
    };
    final lg = size == AppButtonSize.lg;
    final icon = this.icon;

    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
        minimumSize: Size(0, lg ? 56 : 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: variant == AppButtonVariant.ghost ? AppSpacing.s4 : AppSpacing.s6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        textStyle: lg ? AppTextStyles.buttonLg : AppTextStyles.button,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.s2)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );

    final sized = block ? SizedBox(width: double.infinity, child: button) : button;
    return onPressed == null ? Opacity(opacity: disabledOpacity, child: sized) : sized;
  }
}
