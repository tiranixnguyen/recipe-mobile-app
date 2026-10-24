import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/day_strip.dart';
import 'package:recipe_mobile_app/core/widgets/meal_slot.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_view_model.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/recipe_picker_sheet.dart';
import 'package:recipe_mobile_app/features/plan/routes.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Thực đơn theo ngày (prototype `MealPlan`, chế độ Ngày).
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(planViewModelProvider);
    final plannedCount = state.value?.plannedCount;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        PlanStrings.title,
                        style: AppTextStyles.title.copyWith(color: colors.ink),
                      ),
                    ),
                  ),
                  if (plannedCount != null)
                    Text(
                      PlanStrings.plannedCount(plannedCount, PlanState.slotsPerWeek),
                      style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) => _Day(state: value),
                AsyncError() => Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Text(
                    PlanStrings.loadError,
                    style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: AppSpacing.s3,
                ),
                child: AppButton(
                  label: PlanStrings.shopping,
                  block: true,
                  onPressed: () => context.push(shoppingLocation),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Day extends ConsumerWidget {
  const _Day({required this.state});

  final PlanState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(planViewModelProvider.notifier);
    final dayName = DayStrip.fullNames[state.selectedDay];

    Future<void> pick(Meal meal) async {
      final id = await showRecipePicker(context, meal);
      if (id != null) await viewModel.setMeal(meal, id);
    }

    Future<void> act(Meal meal, Recipe recipe) async {
      final action = await _showSlotActions(context, recipe);
      if (!context.mounted) return;
      switch (action) {
        case _SlotAction.view:
          await context.push(recipeLocation(recipe.id));
        case _SlotAction.change:
          await pick(meal);
        case _SlotAction.remove:
          await viewModel.clearMeal(meal);
        case null:
          break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      children: [
        DayStrip(
          selected: state.selectedDay,
          today: state.today,
          daysWithMeals: state.daysWithMeals,
          onSelected: viewModel.selectDay,
        ),
        const SizedBox(height: AppSpacing.s4),
        Semantics(
          header: true,
          child: Text(
            state.selectedDay == state.today ? '$dayName · ${PlanStrings.today}' : dayName,
            style: AppTextStyles.subtitle.copyWith(color: colors.ink),
          ),
        ),
        for (final MapEntry(key: meal, value: recipe) in state.meals.entries) ...[
          const SizedBox(height: AppSpacing.s3),
          Text(
            meal.label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (recipe == null)
            MealSlot.empty(onTap: () => pick(meal))
          else
            MealSlot(
              title: recipe.name,
              meta: recipeMeta(recipe),
              imageAsset: recipe.imageAsset,
              onTap: () => act(meal, recipe),
            ),
        ],
      ],
    );
  }
}

enum _SlotAction { view, change, remove }

Future<_SlotAction?> _showSlotActions(BuildContext context, Recipe recipe) {
  final colors = context.colors;
  return showModalBottomSheet<_SlotAction>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s2),
          child: Text(recipe.name, style: AppTextStyles.title.copyWith(color: colors.ink)),
        ),
        for (final (action, label, icon) in [
          (_SlotAction.view, PlanStrings.viewRecipe, AppIcons.bowl),
          (_SlotAction.change, PlanStrings.changeRecipe, AppIcons.shuffle),
          (_SlotAction.remove, PlanStrings.removeRecipe, AppIcons.trash),
        ])
          ListTile(
            leading: Icon(icon),
            title: Text(label),
            iconColor: action == _SlotAction.remove ? colors.dangerInk : colors.ink,
            textColor: action == _SlotAction.remove ? colors.dangerInk : colors.ink,
            onTap: () => Navigator.of(context).pop(action),
          ),
        const SizedBox(height: AppSpacing.s2),
      ],
    ),
  );
}
