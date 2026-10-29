import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

/// Chip lọc bật/tắt (component `Chip`): thời gian, dụng cụ, bữa, chế độ ăn, nguyên liệu trong Tủ đồ.
///
/// Chưa chọn: nền `surfaceRaised`, viền `outline`. Đã chọn: nền `chiliSoft`, chữ và viền `chiliDeep`,
/// [icon] đổi thành dấu tích. Cao 36, bo pill; xếp cách nhau `AppSpacing.s2`.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  /// Ngắn, cụ thể: "Dưới 15 phút", "Nồi cơm điện", "Bữa tối".
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.chiliDeep : colors.ink;
    final icon = selected ? AppIcons.check : this.icon;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.chiliSoft : colors.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: selected ? colors.chiliDeep : colors.outline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.s1,
                children: [
                  if (icon != null) Icon(icon, size: 16, color: foreground),
                  // Chỗ hẹp (Wrap, chữ phóng to) thì cắt nhãn thay vì tràn.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
