import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Chính sách quyền riêng tư (prototype `Policy`). Nội dung cố định nên không có ViewModel.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: SystemStrings.back,
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: const Text(SystemStrings.policy),
        shape: Border(bottom: BorderSide(color: colors.line)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s5,
            AppSpacing.s5,
            AppSpacing.s8,
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: colors.herbSoft, borderRadius: AppRadius.mdAll),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.shield, color: colors.herbInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        SystemStrings.policySummary,
                        style: AppTextStyles.body.copyWith(fontSize: 14, height: 20 / 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final (title, paragraphs) in SystemStrings.policySections) ...[
              const SizedBox(height: AppSpacing.s5),
              Semantics(header: true, child: Text(title, style: AppTextStyles.subtitle)),
              for (final paragraph in paragraphs) ...[
                const SizedBox(height: 6),
                Text(paragraph, style: AppTextStyles.body),
              ],
            ],
            const SizedBox(height: AppSpacing.s5),
            Text(
              SystemStrings.policyUpdated,
              style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
