import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/inline_banner.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today_prefs/today_prefs_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

class TodayPrefsScreen extends ConsumerWidget {
  const TodayPrefsScreen({super.key, this.fromToday = false});

  /// Mở từ Hôm nay ăn gì (nút sửa tiêu chí): xong thì quay lại màn đó thay vì mở màn mới.
  final bool fromToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayPrefsViewModelProvider);
    final vm = ref.read(todayPrefsViewModelProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s2),
              child: Row(
                children: [
                  BackButton(color: colors.ink),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DiscoverStrings.prefsTitle,
                          style: AppTextStyles.title.copyWith(color: colors.ink),
                        ),
                        Text(
                          DiscoverStrings.prefsSubtitle,
                          style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                children: [
                  const SizedBox(height: AppSpacing.s2),
                  // Quy mô bữa
                  _SectionLabel(DiscoverStrings.prefsScaleLabel),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsScaleOne,
                    hint: DiscoverStrings.prefsScaleOneHint,
                    selected: state.prefs.meal.scale == MealScale.one,
                    onTap: () => vm.setScale(MealScale.one),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsScaleTwo,
                    hint: DiscoverStrings.prefsScaleTwoHint,
                    selected: state.prefs.meal.scale == MealScale.two,
                    onTap: () => vm.setScale(MealScale.two),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsScaleTray,
                    hint: DiscoverStrings.prefsScaleTrayHint,
                    selected: state.prefs.meal.scale == MealScale.tray,
                    onTap: () => vm.setScale(MealScale.tray),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  // Thời gian nấu
                  _SectionLabel(DiscoverStrings.prefsTimeLabel),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsTime15,
                    hint: DiscoverStrings.prefsTime15Hint,
                    selected: state.prefs.meal.maxMinutes == 15,
                    onTap: () => vm.setMinutes(15),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsTime30,
                    hint: DiscoverStrings.prefsTime30Hint,
                    selected: state.prefs.meal.maxMinutes == 30,
                    onTap: () => vm.setMinutes(30),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsTimeNull,
                    hint: DiscoverStrings.prefsTimeNullHint,
                    selected: state.prefs.meal.maxMinutes == null,
                    onTap: () => vm.setMinutes(null),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  // Cảm giác
                  _SectionLabel(DiscoverStrings.prefsFeel),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsFeelWeather,
                    hint: DiscoverStrings.prefsFeelWeatherHint,
                    selected: state.prefs.byWeather,
                    // Chưa bật thì không chọn được, mời bật ở Cài đặt; không tự xin quyền.
                    onTap: state.weatherEnabled ? vm.pickWeather : null,
                    badge: state.weatherEnabled ? null : DiscoverStrings.prefsFeelWeatherDisabled,
                  ),
                  if (!state.weatherEnabled) ...[
                    const SizedBox(height: AppSpacing.s2),
                    InlineBanner(
                      text: DiscoverStrings.prefsWeatherInvite,
                      action: BannerAction(
                        DiscoverStrings.prefsWeatherInviteAction,
                        () => context.push(settingsLocation),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsFeelCooling,
                    hint: DiscoverStrings.prefsFeelCoolingHint,
                    selected: !state.prefs.byWeather && state.prefs.meal.feel == DishFeel.cooling,
                    onTap: () => vm.pickFeel(DishFeel.cooling),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsFeelWarming,
                    hint: DiscoverStrings.prefsFeelWarmingHint,
                    selected: !state.prefs.byWeather && state.prefs.meal.feel == DishFeel.warming,
                    onTap: () => vm.pickFeel(DishFeel.warming),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _OptionTile(
                    label: DiscoverStrings.prefsFeelAny,
                    hint: DiscoverStrings.prefsFeelAnyHint,
                    selected: !state.prefs.byWeather && state.prefs.meal.feel == null,
                    onTap: vm.pickAnyFeel,
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  // Dọn tủ lạnh
                  _FridgeRow(
                    enabled: state.prefs.meal.fridge,
                    onToggle: vm.toggleFridge,
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  // Thêm tiêu chí
                  _MoreSection(state: state, vm: vm),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ),
            ),
            // Footer
            _Footer(state: state, vm: vm, fromToday: fromToday),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: AppTextStyles.subtitle.copyWith(color: colors.ink),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String hint;
  final bool selected;

  /// null thì lựa chọn mờ đi, không bấm được.
  final VoidCallback? onTap;

  /// Nhãn badge nhỏ bên phải nhãn (ví dụ "Chưa bật").
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = selected ? colors.chili : colors.outline;
    final bgColor = selected ? colors.chiliSoft : colors.surfaceRaised;

    final tile = Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio dot
              _RadioDot(selected: selected),
              const SizedBox(width: AppSpacing.s3),
              // Label + hint
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: AppTextStyles.body.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.s2),
                          _Badge(badge!),
                        ],
                      ],
                    ),
                    Text(
                      hint,
                      style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return onTap == null ? Opacity(opacity: AppButton.disabledOpacity, child: tile) : tile;
  }
}

/// Vòng `outline`, đã chọn thì vòng `chili` và chấm `chili` 10px như prototype.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? colors.chili : colors.outline, width: 2),
        ),
        child: selected
            ? Center(
                child: SizedBox.square(
                  dimension: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: colors.chili),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: colors.inkMuted),
      ),
    );
  }
}

class _FridgeRow extends StatelessWidget {
  const _FridgeRow({required this.enabled, required this.onToggle});

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DiscoverStrings.prefsFridge,
                  style: AppTextStyles.body.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DiscoverStrings.prefsFridgeDesc,
                  style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) => onToggle(),
            activeTrackColor: colors.herb,
            activeThumbColor: colors.surfaceRaised,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.state, required this.vm});

  final TodayPrefsState state;
  final TodayPrefsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: vm.toggleMore,
          child: Row(
            children: [
              Text(
                DiscoverStrings.prefsMore(state.pickedTags),
                style: AppTextStyles.subtitle.copyWith(color: colors.chiliDeep),
              ),
              const SizedBox(width: AppSpacing.s1),
              AnimatedRotation(
                turns: state.moreOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down, color: colors.chiliDeep),
              ),
            ],
          ),
        ),
        if (state.moreOpen) ...[
          const SizedBox(height: AppSpacing.s4),
          _TagGroup(
            label: DiscoverStrings.prefsTagsSectionCheap,
            tags: const [RecipeTag.cheap],
            tagLabels: const {RecipeTag.cheap: DiscoverStrings.prefsTagCheap},
            selected: state.prefs.meal.tags,
            onToggle: vm.toggleTag,
          ),
          const SizedBox(height: AppSpacing.s4),
          _TagGroup(
            label: DiscoverStrings.prefsTagsSectionTaste,
            tags: const [RecipeTag.healthy, RecipeTag.veg, RecipeTag.mild],
            tagLabels: const {
              RecipeTag.healthy: DiscoverStrings.prefsTagHealthy,
              RecipeTag.veg: DiscoverStrings.prefsTagVeg,
              RecipeTag.mild: DiscoverStrings.prefsTagMild,
            },
            selected: state.prefs.meal.tags,
            onToggle: vm.toggleTag,
          ),
          const SizedBox(height: AppSpacing.s4),
          _TagGroup(
            label: DiscoverStrings.prefsTagsSectionOccasion,
            tags: const [RecipeTag.snack, RecipeTag.party],
            tagLabels: const {
              RecipeTag.snack: DiscoverStrings.prefsTagSnack,
              RecipeTag.party: DiscoverStrings.prefsTagParty,
            },
            selected: state.prefs.meal.tags,
            onToggle: vm.toggleTag,
          ),
        ],
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.label,
    required this.tags,
    required this.tagLabels,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<RecipeTag> tags;
  final Map<RecipeTag, String> tagLabels;
  final Set<RecipeTag> selected;
  final void Function(RecipeTag) onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final tag in tags)
              AppChip(
                label: tagLabels[tag] ?? tag.label,
                selected: selected.contains(tag),
                onTap: () => onToggle(tag),
              ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state, required this.vm, required this.fromToday});

  final TodayPrefsState state;
  final TodayPrefsViewModel vm;
  final bool fromToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ctaLabel = DiscoverStrings.prefsCta(state.prefs.meal.scale.phrase);
    void done() => fromToday ? context.pop() : context.pushReplacement(todayLocation);

    return Container(
      color: colors.surfaceRaised,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: Row(
              children: [
                AppButton.ghost(
                  label: DiscoverStrings.prefsSkip,
                  onPressed: done,
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: AppButton(
                    label: ctaLabel,
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: () async {
                      await vm.submit();
                      if (context.mounted) done();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
