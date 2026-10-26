import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_step/meal_step_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_step_widgets.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Nấu cả bữa từng bước (prototype `MealCookStep`): tab món, bước của món đang xem, đồng hồ của
/// mọi món; bước cuối món là "Sang món n", bước cuối bữa là "Xong cả bữa".
class MealStepScreen extends ConsumerWidget {
  const MealStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(mealStepViewModelProvider)) {
      AsyncData(:final value) => _MealStep(state: value),
      AsyncError() => const NoMealScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _MealStep extends ConsumerWidget {
  const _MealStep({required this.state});

  final MealStepState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(mealStepViewModelProvider.notifier);
    final recipe = state.recipe;

    Future<void> finish() async {
      final router = GoRouter.of(context);
      await viewModel.finishMeal();
      router.pushReplacement(mealCookDoneLocation);
    }

    final Widget nextButton;
    if (!state.isLastStep) {
      nextButton = AppButton(
        label: CookStrings.nextStep,
        size: AppButtonSize.lg,
        block: true,
        onPressed: viewModel.next,
      );
    } else if (!state.isLastDish) {
      nextButton = AppButton(
        label: CookStrings.nextDish(
          state.current + 2,
          state.dishes[state.current + 1].recipe.name,
        ),
        size: AppButtonSize.lg,
        block: true,
        onPressed: viewModel.next,
      );
    } else {
      nextButton = AppButton(
        label: CookStrings.finishMeal,
        icon: AppIcons.check,
        size: AppButtonSize.lg,
        block: true,
        onPressed: finish,
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepHeader(
              step: state.index + 1,
              total: recipe.steps.length,
              done: state.index + 1,
              title: CookStrings.mealStepTitle(
                state.meal,
                state.current + 1,
                state.dishes.length,
              ),
              showProgress: false,
              below: _DishTabs(state: state, onSelect: viewModel.selectDish),
              onClose: () => context.canPop() ? context.pop() : context.go(planLocation()),
              onIngredients: () => showStepIngredients(
                context,
                title: CookStrings.mealSheetTitle(recipe.name, state.dish.servings),
                servings: state.dish.servings,
                items: state.ingredients,
                basicSpices: state.basicSpices,
              ),
            ),
            Expanded(
              child: StepBody(
                label: CookStrings.mealStepLabel(
                  recipe.name,
                  state.index + 1,
                  recipe.steps.length,
                ),
                text: state.step.text,
                timers: StepTimers(
                  timers: [
                    for (final (dish, step) in state.timedSteps)
                      StepTimerSlot(
                        key: ValueKey(cookTimerKey(dish, step)),
                        visible: state.showsTimer(dish, step),
                        seconds: state.dishes[dish].recipe.steps[step].timerSeconds!,
                        endAt: state.timerEnds[cookTimerKey(dish, step)],
                        label: CookStrings.mealTimerLabel(state.dishes[dish].recipe.name, step + 1),
                        clock: viewModel.clock,
                        onStatusChange: (status) => viewModel.timerChanged(dish, step, status),
                      ),
                  ],
                ),
              ),
            ),
            CookFooter(
              child: Row(
                spacing: AppSpacing.s3,
                children: [
                  // Prototype 1 : 1.6; 1 : 1.4 như màn một món để "Bước trước" không xuống dòng.
                  Expanded(
                    flex: 5,
                    child: AppButton.secondary(
                      label: CookStrings.previousStep,
                      icon: AppIcons.back,
                      size: AppButtonSize.lg,
                      block: true,
                      onPressed: state.isFirst ? null : viewModel.previous,
                    ),
                  ),
                  Expanded(flex: 7, child: nextButton),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab món: "1. Đậu phụ" (dấu check khi xong), thanh đoạn tiến độ, "Bước 2/4" / "4 bước" / "Xong".
class _DishTabs extends StatelessWidget {
  const _DishTabs({required this.state, required this.onSelect});

  final MealStepState state;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s3),
      child: Semantics(
        container: true,
        label: CookStrings.mealDishes,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s2,
          children: [
            for (final (i, dish) in state.dishes.indexed)
              Expanded(
                child: _DishTab(
                  number: i + 1,
                  name: dish.recipe.name,
                  steps: dish.recipe.steps.length,
                  position: state.positions[i],
                  selected: i == state.current,
                  finished: state.finished.contains(i),
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DishTab extends StatelessWidget {
  const _DishTab({
    required this.number,
    required this.name,
    required this.steps,
    required this.position,
    required this.selected,
    required this.finished,
    required this.onTap,
  });

  final int number;
  final String name;
  final int steps;
  final int position;
  final bool selected;
  final bool finished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final started = selected || position > 0;
    final progress = finished
        ? CookStrings.finish
        : started
        ? CookStrings.stepOf(position + 1, steps)
        : CookStrings.dishSteps(steps);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.chiliSoft : colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: selected
              ? BorderSide(color: colors.chili, width: 2)
              : BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.s1,
                children: [
                  Row(
                    spacing: AppSpacing.s1,
                    children: [
                      if (finished) Icon(AppIcons.check, size: 16, color: colors.herbInk),
                      Expanded(
                        child: Text(
                          CookStrings.dishTab(number, name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(color: colors.ink),
                        ),
                      ),
                    ],
                  ),
                  ExcludeSemantics(
                    child: Row(
                      spacing: 3,
                      children: [
                        for (var k = 0; k < steps; k++)
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: finished || (k <= position && started)
                                    ? colors.chili
                                    : colors.line,
                                borderRadius: AppRadius.pillAll,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    progress,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      color: colors.inkMuted,
                    ),
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
