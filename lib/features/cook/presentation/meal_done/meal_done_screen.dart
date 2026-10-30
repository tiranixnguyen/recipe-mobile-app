import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/day_strip.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_done/meal_done_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_done_widgets.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Nấu xong cả bữa (prototype `MealCookDone`): chấm từng món, cập nhật Tủ đồ cả bữa; xong thì về
/// Khám phá.
class MealDoneScreen extends ConsumerWidget {
  const MealDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(mealDoneViewModelProvider)) {
      AsyncData(:final value) => _MealDone(state: value),
      AsyncError() => const NoMealScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _MealDone extends ConsumerWidget {
  const _MealDone({required this.state});

  final MealDoneState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(mealDoneViewModelProvider.notifier);
    final dayName = DayStrip.fullNames[state.slot.day.weekday - 1];

    Future<void> finish() async {
      final router = GoRouter.of(context);
      await viewModel.finish();
      router.go(planLocation(date: state.slot.day, meal: state.slot.meal));
    }

    // "Đã dùng 2 bìa · Đậu phụ sốt cà chua", "… · 2 món".
    String tag(UsedItem item) => item.recipeIds.length > 1
        ? CookStrings.dishesTag(item.recipeIds.length)
        : state.nameOf(item.recipeIds.firstOrNull ?? '');
    final used = [
      for (final item in state.used)
        UsedItem(
          ingredientId: item.ingredientId,
          name: item.name,
          note: '${item.note} · ${tag(item)}',
          recipeIds: item.recipeIds,
        ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s6,
                  AppSpacing.s4,
                  AppSpacing.s3,
                ),
                children: [
                  DoneHero(
                    title: CookStrings.mealDoneTitle(state.slot.meal),
                    meta: CookStrings.mealDoneMeta(
                      state.dishes.length,
                      state.servings,
                      state.minutes,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  const SectionHeader(title: CookStrings.rateEach),
                  const SizedBox(height: AppSpacing.s2),
                  RowsBox(
                    rows: [
                      for (final (i, d) in state.dishes.indexed)
                        _DishRating(
                          name: d.recipe.name,
                          selected: state.ratings[i],
                          onSelect: (rating) => viewModel.rate(i, rating),
                        ),
                    ],
                  ),
                  if (used.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s5),
                    UpdatePantrySection(
                      title: CookStrings.mealUpdatePantry,
                      hint: CookStrings.mealUpdatePantryHint,
                      items: used,
                      usedUp: state.usedUp,
                      onToggle: viewModel.toggleUsedUp,
                    ),
                  ],
                ],
              ),
            ),
            CookFooter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.s2,
                children: [
                  Text(
                    CookStrings.mealMarked(state.slot.meal, dayName),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                  AppButton(
                    label: used.isEmpty ? CookStrings.finish : CookStrings.finishAndUpdate,
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: state.finishing ? null : finish,
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

/// Một món: tên, "Bạn chấm: Ngon" / "Chưa chấm", ba nút icon Ngon / Tạm / Chê 44px.
class _DishRating extends StatelessWidget {
  const _DishRating({required this.name, required this.selected, required this.onSelect});

  final String name;
  final CookRating? selected;
  final ValueChanged<CookRating> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = this.selected;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Row(
        spacing: AppSpacing.s2,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                  Text(
                    selected == null ? CookStrings.notRated : CookStrings.ratedAs(selected.label),
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
          for (final rating in CookRating.values)
            IconButton(
              onPressed: () => onSelect(rating),
              tooltip: CookStrings.rateDish(rating.label, name),
              isSelected: rating == selected,
              icon: Icon(ratingIcon(rating)),
              style: IconButton.styleFrom(
                fixedSize: const Size.square(44),
                minimumSize: const Size.square(44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                backgroundColor: rating == selected ? colors.chiliSoft : colors.surfaceRaised,
                foregroundColor: rating == selected ? colors.chiliDeep : colors.ink,
                side: BorderSide(color: rating == selected ? colors.chiliSoft : colors.outline),
              ),
            ),
        ],
      ),
    );
  }
}
