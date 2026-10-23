import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../discover/discover.dart';
import '../../strings.dart';
import 'onboarding_view_model.dart';

/// Chọn dụng cụ và chế độ ăn (prototype `Onboarding`).
///
/// Lần đầu mở app: có "Bỏ qua", Xong thì vào app. [editing] (mở từ Cài đặt): có nút quay lại, Lưu
/// thì quay về màn trước.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, this.editing = false});

  final bool editing;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingViewModelProvider.notifier).save();
    if (!context.mounted) return;
    // TODO(SYS-03): lần đầu thì Xong đi NotifPermission rồi mới vào Khám phá.
    editing ? context.pop() : context.go(discoverLocation);
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingViewModelProvider.notifier).skip();
    if (context.mounted) context.go(discoverLocation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    final busy = state.finishing;

    return Scaffold(
      appBar: editing
          ? AppBar(
              leading: IconButton(
                icon: const Icon(AppIcons.back),
                tooltip: SystemStrings.back,
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!editing)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s2,
                  AppSpacing.s2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        SystemStrings.onboardingStep,
                        style: AppTextStyles.label.copyWith(color: colors.inkMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => _skip(context, ref),
                      child: const Text(SystemStrings.onboardingSkip),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s2,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                children: [
                  const Text(SystemStrings.onboardingTitle, style: AppTextStyles.display),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    SystemStrings.onboardingIntro,
                    style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  const _SectionTitle(SystemStrings.onboardingTools),
                  GridView(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.s2,
                      crossAxisSpacing: AppSpacing.s2,
                      mainAxisExtent: 72,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final tool in Tool.values)
                        _ToolTile(
                          label: tool.label,
                          selected: state.tools.contains(tool),
                          onTap: () => viewModel.toggleTool(tool),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  const _SectionTitle(SystemStrings.onboardingDiets),
                  Wrap(
                    spacing: AppSpacing.s2,
                    runSpacing: AppSpacing.s2,
                    children: [
                      for (final diet in Diet.values)
                        _DietChip(
                          label: diet.label,
                          selected: state.diets.contains(diet),
                          onTap: () => viewModel.toggleDiet(diet),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s6,
          ),
          child: FilledButton(
            onPressed: busy ? null : () => _save(context, ref),
            child: Text(editing ? SystemStrings.kitchenEditSave : SystemStrings.onboardingDone),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Semantics(header: true, child: Text(text, style: AppTextStyles.subtitle)),
    );
  }
}

/// Ô dụng cụ: ô tích bên trái, viền `chili` 2px khi chọn.
class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      checked: selected,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: selected
              ? BorderSide(color: colors.chili, width: 2)
              : BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? colors.chili : Colors.transparent,
                    border: Border.all(color: selected ? colors.chili : colors.outline, width: 2),
                    // Ô tích bo 6px như prototype; nhỏ hơn mọi token radius.
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: selected
                      ? Icon(
                          AppIcons.check,
                          size: 16,
                          weight: 700,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip chế độ ăn: cao 40, bo pill; chọn thì nền `chiliSoft`, chữ `chiliDeep`.
class _DietChip extends StatelessWidget {
  const _DietChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      checked: selected,
      child: Material(
        color: selected ? colors.chiliSoft : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: selected ? colors.chiliSoft : colors.outline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: selected ? colors.chiliDeep : colors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
