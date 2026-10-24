import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';

/// Cho biết món nấu được ngay với đồ trong Tủ đồ hay không (component `AvailabilityBadge`).
///
/// - [missing] rỗng: "Đủ đồ" nền `herb`, chữ trắng.
/// - Còn thiếu: "Thiếu: hành lá, cà chua" nền `chiliSoft`, chữ `chiliDeep`.
///
/// [missing] là tên nguyên liệu viết thường, tiếng Việt có dấu; lấy từ `availabilityFor` của Tủ đồ.
/// Nên chỉ hiện khi thiếu 1–2 thứ; thiếu nhiều hơn thì đừng gợi ý món đó.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({super.key, this.missing = const []});

  final List<String> missing;

  static const ready = 'Đủ đồ';
  static String missingLabel(List<String> missing) => 'Thiếu: ${missing.join(', ')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isReady = missing.isEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isReady ? colors.herb : colors.chiliSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 2),
        child: Text(
          isReady ? ready : missingLabel(missing),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // Chữ trắng trên `herb` như design (5.3:1), cùng màu chữ trên nút `chili`.
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isReady ? Colors.white : colors.chiliDeep,
          ),
        ),
      ),
    );
  }
}
