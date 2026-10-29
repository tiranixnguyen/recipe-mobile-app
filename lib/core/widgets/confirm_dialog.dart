import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';

/// Hộp thoại xác nhận theo board `Toasts`, **chỉ** cho thao tác không hoàn tác được ("Xoá toàn bộ
/// dữ liệu?"). Thao tác hoàn tác được thì làm ngay và cho Hoàn tác qua `AppSnackbar`, không hỏi lại.
///
/// [confirmLabel] nói rõ việc sẽ làm ("Xoá hết"), nằm bên phải, nền `danger`. Trả `true` khi bấm nút
/// đó; Huỷ, bấm ra ngoài hoặc Back trả `false`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Huỷ',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return confirmed ?? false;
}

/// Nội dung của [showConfirmDialog]; màn gọi hàm, không dựng widget này trực tiếp.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Huỷ',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: colors.line),
      ),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.subtitle.copyWith(color: colors.ink)),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  height: 18 / 13,
                  color: colors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: cancelLabel,
                      block: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: AppButton.danger(
                      label: confirmLabel,
                      block: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
