import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/system/presentation/notif_permission/notif_permission_view_model.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Giải thích trước khi xin quyền thông báo (prototype `NotifPermission`).
///
/// Đóng màn với kết quả `true` khi được cho phép, `false` khi từ chối hoặc bấm "Để sau".
class NotifPermissionScreen extends ConsumerWidget {
  const NotifPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final busy = ref.watch(notifPermissionViewModelProvider).busy;
    final viewModel = ref.read(notifPermissionViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s6,
                    vertical: AppSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: colors.chiliSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(AppIcons.bell, size: 52, color: colors.chili),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        SystemStrings.notifAskTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        SystemStrings.notifAskIntro,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                      ),
                      const SizedBox(height: 28),
                      const _Reason(
                        icon: AppIcons.timer,
                        title: SystemStrings.notifAskTimer,
                        note: SystemStrings.notifAskTimerNote,
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      const _Reason(
                        icon: AppIcons.calendar,
                        title: SystemStrings.notifAskMeal,
                        note: SystemStrings.notifAskMealNote,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: SystemStrings.notifAllow,
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: busy
                        ? null
                        : () async {
                            final granted = await viewModel.allow();
                            if (context.mounted) context.pop(granted);
                          },
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  AppButton.ghost(
                    label: SystemStrings.notifLater,
                    block: true,
                    onPressed: busy
                        ? null
                        : () async {
                            await viewModel.later();
                            if (context.mounted) context.pop(false);
                          },
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    SystemStrings.notifAskFooter,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một lý do bật thông báo: icon `chili`, tiêu đề và ghi chú trong thẻ viền `line`.
class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.title, required this.note});

  final IconData icon;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.chili),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: AppTextStyles.meta.copyWith(
                      color: colors.inkMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
