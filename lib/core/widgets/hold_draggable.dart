import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';

/// Trạng thái kéo thả chung của app: thứ đang được kéo bằng [HoldDraggable], `null` khi không kéo.
///
/// Đích thả (`ShoppingFab`, thùng rác ở Đã lưu) nghe để nổi to lên ngay khi bắt đầu kéo, trước khi
/// ngón tay tới gần.
abstract final class AppDrag {
  static final active = ValueNotifier<Object?>(null);
}

/// Quy ước kéo thả nhấn giữ của app: giữ 350ms mới nhấc lên (rung nhẹ), vuốt trước đó là cuộn.
///
/// Thả trúng đích thì rung `selectionClick`. Kéo thả không dùng được với trình đọc màn hình nên luôn
/// có đường thay thế: [semanticsActionLabel] hiện trong menu hành động của TalkBack và gọi
/// [onSemanticsAction] (ví dụ "Thêm vào đi chợ").
///
/// Dùng ở Tủ đồ (chip nguyên liệu → `ShoppingFab`) và Đã lưu (thẻ → thùng rác).
class HoldDraggable<T extends Object> extends StatelessWidget {
  const HoldDraggable({
    super.key,
    required this.data,
    required this.child,
    required this.semanticsActionLabel,
    required this.onSemanticsAction,
    this.feedback,
    this.liftedRadius = AppRadius.pillAll,
  });

  final T data;
  final Widget child;

  /// Thứ đi theo ngón tay; mặc định là [child] phóng 1.06 có bóng.
  final Widget? feedback;

  /// Bo góc của bóng ở feedback mặc định: chip là pill, thẻ món dùng `AppRadius.mdAll`.
  final BorderRadius liftedRadius;
  final String semanticsActionLabel;
  final VoidCallback onSemanticsAction;

  static const delay = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: semanticsActionLabel): onSemanticsAction,
      },
      child: LongPressDraggable<T>(
        data: data,
        delay: delay,
        hapticFeedbackOnStart: false,
        onDragStarted: () {
          HapticFeedback.mediumImpact();
          AppDrag.active.value = data;
        },
        onDragEnd: (details) {
          if (details.wasAccepted) HapticFeedback.selectionClick();
          AppDrag.active.value = null;
        },
        onDraggableCanceled: (_, _) => AppDrag.active.value = null,
        childWhenDragging: Opacity(opacity: .35, child: child),
        feedback: feedback ?? _Lifted(radius: liftedRadius, child: child),
        child: child,
      ),
    );
  }
}

class _Lifted extends StatelessWidget {
  const _Lifted({required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.06,
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [
              // Bóng `0 10px 24px rgba(20,14,10,.28)` của chip đang kéo trong prototype Pantry.
              BoxShadow(color: Color(0x47140E0A), offset: Offset(0, 10), blurRadius: 24),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
