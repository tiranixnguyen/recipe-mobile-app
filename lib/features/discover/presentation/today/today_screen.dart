import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/inline_banner.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Hôm nay ăn gì v2 (prototype `Today`): gợi ý cả bữa theo tiêu chí ở Gợi ý cho mình.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      todayMealsProvider,
      (_, _) => ref.read(todayViewModelProvider.notifier).suggested(),
      fireImmediately: true,
    );
  }

  Future<void> _toggleSave(int dishes) async {
    final saved = await ref.read(todayViewModelProvider.notifier).toggleSave();
    if (saved == null || !mounted) return;
    if (saved) {
      AppSnackbar.show(
        context,
        dishes > 1 ? DiscoverStrings.todaySavedMeal : DiscoverStrings.todaySavedDish,
        action: SnackAction(
          DiscoverStrings.todayView,
          () => context.go(savedLocation(tab: SavedTab.meals)),
        ),
      );
    } else {
      AppSnackbar.show(context, DiscoverStrings.todayUnsaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(todayViewModelProvider);
    final meals = ref.watch(todayMealsProvider);
    final vm = ref.read(todayViewModelProvider.notifier);
    final main = meals.value?.main;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(meal: state.meal),
            Expanded(
              child: switch (meals) {
                AsyncData(:final value) when main != null => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s2,
                    AppSpacing.s4,
                    AppSpacing.s4,
                  ),
                  children: [
                    if (value.relaxedNote case final note?) ...[
                      InlineBanner(text: note),
                      const SizedBox(height: 14),
                    ],
                    _MealCard(meal: main, onSwap: vm.swapDish),
                    const SizedBox(height: 14),
                    Row(
                      spacing: AppSpacing.s3,
                      children: [
                        Expanded(
                          child: Semantics(
                            expanded: state.showReasons,
                            child: AppButton.ghost(
                              label: DiscoverStrings.todayDislike,
                              block: true,
                              onPressed: vm.toggleReasons,
                            ),
                          ),
                        ),
                        Expanded(
                          child: AppButton.secondary(
                            label: DiscoverStrings.todayShuffle,
                            icon: AppIcons.shuffle,
                            block: true,
                            onPressed: vm.shuffle,
                          ),
                        ),
                      ],
                    ),
                    if (state.showReasons) ...[
                      const SizedBox(height: 14),
                      _Reasons(onPick: vm.dislike),
                    ],
                    if (value.alternatives.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        DiscoverStrings.todayAlternatives,
                        style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                      ),
                      for (final (i, alt) in value.alternatives.indexed) ...[
                        const SizedBox(height: AppSpacing.s2),
                        _AltRow(meal: alt, onTap: () => vm.pickAlt(i)),
                      ],
                    ],
                  ],
                ),
                AsyncData() => _Message(DiscoverStrings.todayEmpty),
                AsyncError() => _Message(DiscoverStrings.loadError),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            if (main != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  border: Border(top: BorderSide(color: colors.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s3,
                    AppSpacing.s4,
                    AppSpacing.s4,
                  ),
                  child: Row(
                    spacing: AppSpacing.s3,
                    children: [
                      _SaveButton(
                        saved: meals.value!.isSaved,
                        onPressed: () => _toggleSave(main.dishes.length),
                      ),
                      Expanded(
                        child: AppButton(
                          label: DiscoverStrings.todayAddToPlan,
                          block: true,
                          onPressed: () => vm.addToPlan(
                            (dishes) => showAddMealToPlanSheet(context, dishes),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final criteria = ref.watch(todayCriteriaProvider);
    final chipStyle = AppTextStyles.caption.copyWith(
      color: colors.chiliDeep,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s1, right: AppSpacing.s4),
            child: Row(
              spacing: AppSpacing.s1,
              children: [
                BackButton(color: colors.ink),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          DiscoverStrings.todayTitle(meal.label.toLowerCase()),
                          style: AppTextStyles.title.copyWith(color: colors.ink),
                        ),
                      ),
                      Text(
                        DiscoverStrings.todaySubtitle,
                        style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: DiscoverStrings.todayCriteriaAria(criteria),
            excludeSemantics: true,
            child: InkWell(
              // Sửa xong, Gợi ý cho mình mở lại màn này thay cho chính nó.
              onTap: () => context.pushReplacement(todayPrefsLocation),
              // "Sửa" luôn hiện ở bên phải, chip dài thì cuộn ngang.
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: AppSpacing.s4, top: 2, bottom: 2),
                        child: Row(
                          spacing: 6,
                          children: [
                            for (final label in criteria)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.chiliSoft,
                                  borderRadius: AppRadius.pillAll,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: Text(label, style: chipStyle),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        spacing: 2,
                        children: [
                          Icon(AppIcons.sliders, size: 14, color: colors.chiliDeep),
                          Text(DiscoverStrings.todayEdit, style: chipStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onSwap});

  final TodayMeal meal;
  final ValueChanged<int> onSwap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = AppTextStyles.meta.copyWith(color: colors.inkMuted);
    return Semantics(
      container: true,
      label: DiscoverStrings.todayMealAria,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: colors.line),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 168,
                child: MealMosaic(
                  dishes: [for (final d in meal.dishes) MosaicDish(d.name, d.imageAsset)],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  14,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s3,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AvailabilityBadge(missing: meal.missing),
                        Text(
                          DiscoverStrings.todayMealMeta(
                            meal.dishes.length,
                            meal.totalMinutes,
                            meal.tools,
                          ),
                          style: muted.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    for (final (i, dish) in meal.dishes.indexed)
                      _DishRow(dish: dish, onSwap: () => onSwap(i)),
                    Text(meal.reasons.join(' · '), style: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({required this.dish, required this.onSwap});

  final Recipe dish;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      spacing: 10,
      children: [
        SizedBox(
          width: 76,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.chiliSoft, borderRadius: AppRadius.smAll),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                dish.role.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: colors.chiliDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => context.push(recipeLocation(dish.id)),
            borderRadius: AppRadius.smAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: colors.ink,
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DiscoverStrings.minutes(dish.minutes),
                  style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: DiscoverStrings.todaySwapAria(dish.name),
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            shape: StadiumBorder(side: BorderSide(color: colors.outline)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onSwap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.s1,
                    children: [
                      Icon(AppIcons.shuffle, size: 14, color: colors.ink),
                      Text(
                        DiscoverStrings.todaySwap,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Reasons extends StatelessWidget {
  const _Reasons({required this.onPick});

  final ValueChanged<DislikeReason> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s2,
          children: [
            Text(
              DiscoverStrings.todayReasonsPrompt,
              style: AppTextStyles.label.copyWith(color: colors.ink, fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final reason in DislikeReason.values)
                  AppChip(label: reason.label, selected: false, onTap: () => onPick(reason)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AltRow extends StatelessWidget {
  const _AltRow({required this.meal, required this.onTap});

  final TodayMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s2),
          child: Row(
            spacing: 10,
            children: [
              ExcludeSemantics(
                child: MealMosaic(
                  size: 48,
                  radius: AppRadius.smAll,
                  dishes: [for (final d in meal.dishes) MosaicDish(d.name, d.imageAsset)],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.names,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.ink,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DiscoverStrings.todayAltMeta(
                        meal.dishes.length,
                        meal.totalMinutes,
                        ready: meal.missing.isEmpty,
                      ),
                      style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lưu lại / Đã lưu: `AppButton.secondary`, đã lưu thì chữ `chiliDeep`, viền `chili`, icon tô.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget button = IconTheme.merge(
      data: IconThemeData(fill: saved ? 1 : 0),
      child: AppButton.secondary(
        label: saved ? DiscoverStrings.todaySaved : DiscoverStrings.todaySave,
        icon: AppIcons.bookmark,
        onPressed: onPressed,
      ),
    );
    if (saved) {
      // AppButton lấy màu từ theme: đổi token cục bộ cho trạng thái đã lưu như prototype.
      final theme = Theme.of(context);
      button = Theme(
        data: theme.copyWith(
          extensions: [colors.copyWith(ink: colors.chiliDeep, outline: colors.chili)],
        ),
        child: button,
      );
    }
    return Semantics(toggled: saved, child: button);
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.s4),
    child: Text(text, style: AppTextStyles.body.copyWith(color: context.colors.inkMuted)),
  );
}
