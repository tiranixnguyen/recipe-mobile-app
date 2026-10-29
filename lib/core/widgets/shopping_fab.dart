import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';

/// Nút nổi Đi chợ ở Tủ đồ và Thực đơn (prototype `Pantry`, `MealPlan`): tròn 56, nền `chili`, icon
/// giỏ, badge đếm số thứ chưa mua.
///
/// [count] do feature truyền vào (đếm dòng chưa tick từ public API của F4); core không đọc thẳng danh
/// sách đi chợ. Có [onAccept] thì nút cũng là đích thả cho [HoldDraggable]: nổi to khi đang kéo một
/// thứ kiểu [T], vòng `chiliSoft` dày lên khi đè lên nút.
///
/// ```dart
/// ShoppingFab<Ingredient>(
///   count: unticked,
///   onPressed: () => context.push(shoppingLocation),
///   onAccept: (ingredient) => viewModel.addToShopping(ingredient),
/// )
/// ```
class ShoppingFab<T extends Object> extends StatelessWidget {
  const ShoppingFab({
    super.key,
    required this.count,
    required this.onPressed,
    this.onWillAccept,
    this.onAccept,
  });

  final int count;
  final VoidCallback onPressed;

  /// Lọc thứ được thả; mặc định nhận mọi [T].
  final bool Function(T data)? onWillAccept;
  final void Function(T data)? onAccept;

  static const tooltip = 'Đi chợ';
  static String semanticsLabel(int count) => count == 0 ? tooltip : '$tooltip, $count thứ cần mua';

  @override
  Widget build(BuildContext context) {
    final onAccept = this.onAccept;
    if (onAccept == null) return _Fab(count: count, onPressed: onPressed, ring: 0);

    return ValueListenableBuilder<Object?>(
      valueListenable: AppDrag.active,
      builder: (context, dragging, _) => DragTarget<T>(
        onWillAcceptWithDetails: (details) => onWillAccept?.call(details.data) ?? true,
        onAcceptWithDetails: (details) {
          HapticFeedback.selectionClick();
          onAccept(details.data);
        },
        builder: (context, candidates, _) {
          final lifting = dragging is T;
          return AnimatedScale(
            scale: lifting ? 1.15 : 1,
            duration: const Duration(milliseconds: 150),
            child: _Fab(
              count: count,
              onPressed: onPressed,
              ring: candidates.isNotEmpty
                  ? 14
                  : lifting
                  ? 8
                  : 0,
            ),
          );
        },
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.count, required this.onPressed, required this.ring});

  final int count;
  final VoidCallback onPressed;

  /// Độ dày vòng `chiliSoft` quanh nút khi đang kéo (8) hoặc đè lên (14).
  final double ring;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: ShoppingFab.semanticsLabel(count),
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (ring > 0) BoxShadow(color: colors.chiliSoft, spreadRadius: ring),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              heroTag: null,
              onPressed: onPressed,
              tooltip: ShoppingFab.tooltip,
              backgroundColor: colors.chili,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(AppIcons.basket),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('shopping-fab-badge'),
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: AppRadius.pillAll,
                      border: Border.all(color: colors.chili, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      textScaler: TextScaler.noScaling,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.chiliDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
