import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';

enum BannerKind {
  /// Nền `chiliSoft`, chữ `chiliDeep`, icon `info`: "Đã nới thời gian lên 45 phút…".
  info,

  /// Nền `herbSoft`, chữ `ink`, icon `check` màu `herbInk`: "Sẽ thêm cùng Canh cà chua trứng…".
  success,
}

/// Hành động bên phải banner, ví dụ "Sửa".
class BannerAction {
  const BannerAction(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

/// Banner trong màn theo board `Toasts`: trạng thái còn đúng khi người dùng ở màn, nằm trong nội
/// dung, không tự ẩn. Báo kết quả một thao tác vừa xong thì dùng `AppSnackbar`.
class InlineBanner extends StatelessWidget {
  const InlineBanner({super.key, required this.text, this.kind = BannerKind.info, this.action});

  final String text;
  final BannerKind kind;
  final BannerAction? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color background, Color foreground, IconData icon, Color iconColor) = switch (kind) {
      BannerKind.info => (colors.chiliSoft, colors.chiliDeep, AppIcons.info, colors.chiliDeep),
      BannerKind.success => (colors.herbSoft, colors.ink, AppIcons.check, colors.herbInk),
    };
    final action = this.action;
    final style = AppTextStyles.body.copyWith(fontSize: 13, height: 18 / 13, color: foreground);

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: AppRadius.mdAll),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 10),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, size: 18, color: iconColor)),
              const SizedBox(width: AppSpacing.s2),
              Expanded(child: Text(text, style: style)),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.s2),
                TextButton(
                  onPressed: action.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.chiliDeep,
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                    textStyle: style.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: Text(action.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
