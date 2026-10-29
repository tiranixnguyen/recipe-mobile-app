import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

enum SnackKind {
  /// "Đã + việc + nơi": icon `check` màu `herbSoft`.
  success,

  /// Đã tồn tại ("Trứng gà đã có trong đi chợ"): icon `info`.
  info,

  /// Lỗi nhẹ thử lại được ("Chưa lưu được thực đơn"): nền `danger`, kèm nút Thử lại.
  error,
}

/// Nút duy nhất của snackbar: Hoàn tác, Xem hoặc Thử lại.
class SnackAction {
  const SnackAction(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

/// Snackbar theo board `Toasts` — mọi màn báo kết quả thao tác bằng hàm này, không tự `SnackBar(...)`.
///
/// Mỗi lúc một cái: cái mới thay cái cũ ngay. Tự ẩn sau 4 giây, có [SnackAction] thì 6 giây. Snackbar
/// lên `Scaffold` gốc nên tự nằm trên thanh điều hướng; màn có nút nổi ở `Scaffold` riêng thì truyền
/// `besideFab: true` để snackbar chừa chỗ bên phải cho nút.
///
/// ```dart
/// AppSnackbar.show(context, 'Đã bỏ lưu món', action: SnackAction('Hoàn tác', undo));
/// AppSnackbar.show(context, 'Chưa lưu được thực đơn.', kind: SnackKind.error, action: …);
/// ```
abstract final class AppSnackbar {
  static const duration = Duration(seconds: 4);
  static const durationWithAction = Duration(seconds: 6);

  /// Đang có snackbar trên màn hay không; `TipBubble` nghe để ẩn mẹo khi có snackbar.
  static final visible = ValueNotifier<bool>(false);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String text, {
    SnackKind kind = SnackKind.success,
    SnackAction? action,
    bool besideFab = false,
  }) {
    final colors = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    final error = kind == SnackKind.error;
    final background = error ? colors.danger : colors.ink;
    final foreground = error ? Colors.white : colors.surface;
    final (IconData icon, Color iconColor) = switch (kind) {
      SnackKind.success => (AppIcons.check, colors.herbSoft),
      SnackKind.info => (AppIcons.info, foreground),
      SnackKind.error => (AppIcons.alert, foreground),
    };

    final controller = (messenger..hideCurrentSnackBar()).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          AppSpacing.s4,
          0,
          besideFab ? 88 : AppSpacing.s4,
          AppSpacing.s4,
        ),
        padding: EdgeInsets.zero,
        backgroundColor: background,
        elevation: 6,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        duration: action == null ? duration : durationWithAction,
        // TalkBack cần thời gian tới được nút: giữ snackbar tới khi bấm hoặc vuốt bỏ.
        persist: action != null && MediaQuery.accessibleNavigationOf(context),
        content: _SnackContent(
          text: text,
          icon: icon,
          iconColor: iconColor,
          foreground: foreground,
          actionColor: error ? Colors.white : colors.chiliSoft,
          underlineAction: error,
          action: action,
          onAction: () {
            messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            action?.onTap();
          },
        ),
      ),
    );

    visible.value = true;
    controller.closed.then((_) {
      // Cái cũ đóng sau khi cái mới đã hiện thì không được tắt cờ.
      if (identical(_current, controller)) visible.value = false;
    });
    _current = controller;

    if (error) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
        assertiveness: Assertiveness.assertive,
      );
    }
    return controller;
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _current;
}

class _SnackContent extends StatelessWidget {
  const _SnackContent({
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.foreground,
    required this.actionColor,
    required this.underlineAction,
    required this.action,
    required this.onAction,
  });

  final String text;
  final IconData icon;
  final Color iconColor;
  final Color foreground;
  final Color actionColor;
  final bool underlineAction;
  final SnackAction? action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: iconColor)),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: foreground,
                  ),
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: actionColor,
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                  textStyle: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: underlineAction ? TextDecoration.underline : null,
                    decorationColor: actionColor,
                  ),
                ),
                child: Text(action.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
