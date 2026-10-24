import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Chỉnh khẩu phần bằng hai nút − / + (component `ServingStepper`), đặt bên phải dòng "Khẩu phần"
/// ở màn Chi tiết món và Chuẩn bị nấu.
///
/// Điều khiển từ ngoài: truyền [value] và [onChanged]. Chạm [min]/[max] thì nút tương ứng mờ và
/// không bấm được.
class ServingStepper extends StatelessWidget {
  const ServingStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 6,
    this.unit = 'người',
    this.label = 'Khẩu phần',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// "người", "suất", "phần"…
  final String unit;

  /// Nhãn cho trình đọc màn hình.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s1,
        children: [
          _RoundButton(
            icon: AppIcons.minus,
            tooltip: 'Bớt một $unit',
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Semantics(
              liveRegion: true,
              child: Text(
                '$value $unit',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                ),
              ),
            ),
          ),
          _RoundButton(
            icon: AppIcons.plus,
            tooltip: 'Thêm một $unit',
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Nút tròn 44px, viền `outline`, nền `surfaceRaised`.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        minimumSize: const Size.square(44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colors.surfaceRaised,
        disabledBackgroundColor: colors.surfaceRaised,
        foregroundColor: colors.ink,
        disabledForegroundColor: colors.ink,
        side: BorderSide(color: colors.outline),
      ),
    );
    return onPressed == null ? Opacity(opacity: AppButton.disabledOpacity, child: button) : button;
  }
}
