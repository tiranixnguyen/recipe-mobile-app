import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_logo.dart';
import 'package:recipe_mobile_app/core/widgets/settings_row.dart';
import 'package:recipe_mobile_app/features/system/presentation/about/about_view_model.dart';
import 'package:recipe_mobile_app/features/system/routes.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Giới thiệu (prototype `About`).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _appName = 'Bếp Hoà Lạc';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final version = ref.watch(aboutViewModelProvider).version;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: SystemStrings.back,
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: const Text(SystemStrings.about),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s6,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                children: [
                  const Center(child: AppLogo(size: 96)),
                  const SizedBox(height: AppSpacing.s3),
                  const Text(_appName, textAlign: TextAlign.center, style: AppTextStyles.display),
                  if (version != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      SystemStrings.aboutVersion(version),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s3),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: const Text(
                        SystemStrings.aboutIntro,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  SettingsGroup(
                    children: [
                      const _InfoRow(label: SystemStrings.aboutTeam, value: SystemStrings.teamName),
                      _InfoRow(
                        label: SystemStrings.aboutContact,
                        value: SystemStrings.contactEmail,
                        link: true,
                        onTap: () => _copyEmail(context),
                      ),
                      SettingsRow(
                        title: SystemStrings.policy,
                        onTap: () => context.push(policyLocation),
                      ),
                      SettingsRow(
                        title: SystemStrings.aboutLicenses,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: _appName,
                          applicationVersion: version,
                          applicationIcon: const Padding(
                            padding: EdgeInsets.all(AppSpacing.s2),
                            child: AppLogo(size: 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s6,
              ),
              child: Text(
                SystemStrings.aboutFooter,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App không có thư viện mở mail, chép địa chỉ để người dùng dán vào app mail.
  static Future<void> _copyEmail(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: SystemStrings.contactEmail));
    messenger.showSnackBar(const SnackBar(content: Text(SystemStrings.aboutEmailCopied)));
  }
}

/// Hàng nhãn bên trái, giá trị bên phải; [link] tô `chiliDeep` như liên kết.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.link = false, this.onTap});

  final String label;
  final String value;
  final bool link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chữ to hay màn hẹp: nhãn và giá trị chia nhau bề ngang, cùng xuống dòng.
              Flexible(child: Text(label, style: AppTextStyles.body)),
              const SizedBox(width: AppSpacing.s3),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: link ? colors.chiliDeep : colors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
