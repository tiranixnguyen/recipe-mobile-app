import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/settings_row.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_view_model.dart';
import 'package:recipe_mobile_app/features/system/routes.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Cài đặt (prototype `Settings`).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    final version = state.version;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: SystemStrings.back,
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: const Text(SystemStrings.settings),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s3,
          ),
          children: [
            _ThemePicker(selected: state.themeMode, onChanged: viewModel.setThemeMode),
            const SizedBox(height: AppSpacing.s4),
            SettingsGroup(
              title: SystemStrings.kitchenSection,
              children: [
                SettingsRow(
                  icon: AppIcons.sliders,
                  title: SystemStrings.kitchenEdit,
                  onTap: () => context.push(kitchenEditLocation),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            SettingsGroup(
              title: SystemStrings.notifSection,
              children: [
                SettingsRow.toggle(
                  icon: AppIcons.timer,
                  title: SystemStrings.notifTimer,
                  note: SystemStrings.notifTimerNote,
                  value: state.timerDone,
                  onChanged: viewModel.setTimerDone,
                ),
                SettingsRow.toggle(
                  icon: AppIcons.bell,
                  title: SystemStrings.notifMeal,
                  note: SystemStrings.notifMealNote,
                  value: state.mealReminder,
                  onChanged: viewModel.setMealReminder,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            SettingsGroup(
              title: SystemStrings.supportSection,
              children: [
                SettingsRow(
                  icon: AppIcons.mail,
                  title: SystemStrings.feedback,
                  onTap: () => context.push(feedbackLocation),
                ),
                SettingsRow(
                  icon: AppIcons.smile,
                  title: SystemStrings.rateApp,
                  onTap: viewModel.rateApp,
                ),
                SettingsRow(
                  icon: AppIcons.shield,
                  title: SystemStrings.policy,
                  onTap: () => context.push(policyLocation),
                ),
                SettingsRow(
                  icon: AppIcons.info,
                  title: SystemStrings.about,
                  onTap: () => context.push(aboutLocation),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            SettingsGroup(
              title: SystemStrings.dataSection,
              children: [
                SettingsRow(
                  icon: AppIcons.trash,
                  title: SystemStrings.clearData,
                  danger: true,
                  onTap: () => context.push(clearDataLocation),
                ),
              ],
            ),
            if (version != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                SystemStrings.version(version),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chọn Sáng / Tối / Theo hệ thống: ba ô trong một khung viền `outline`, ô đang chọn nền `chiliSoft`.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onChanged});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.light, SystemStrings.themeLight, AppIcons.sun),
    (ThemeMode.dark, SystemStrings.themeDark, AppIcons.moon),
    (ThemeMode.system, SystemStrings.themeSystem, AppIcons.device),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hint = SystemStrings.themeHint(
      followSystem: selected == ThemeMode.system,
      dark: Theme.of(context).brightness == Brightness.dark,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            SystemStrings.themeSection,
            style: AppTextStyles.label.copyWith(color: colors.inkMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            border: Border.all(color: colors.outline),
            borderRadius: AppRadius.mdAll,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s1),
            // Ba ô cao bằng nhau kể cả khi một nhãn xuống dòng.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (mode, label, icon)) in _options.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.s1),
                    Expanded(
                      child: _ThemeOption(
                        label: label,
                        icon: icon,
                        selected: mode == selected,
                        onTap: () => onChanged(mode),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(hint, style: AppTextStyles.caption.copyWith(color: colors.inkMuted)),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.chiliDeep : colors.ink;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: selected ? colors.chiliSoft : Colors.transparent,
        borderRadius: AppRadius.smAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // Cao tối thiểu 52 như prototype; chữ to hoặc màn hẹp thì nhãn xuống dòng, ô cao theo.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
