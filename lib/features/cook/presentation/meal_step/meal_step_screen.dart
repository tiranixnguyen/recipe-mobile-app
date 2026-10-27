import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_screen.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_step/meal_step_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/confirm_sheet.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_step_widgets.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/prep_task_tile.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/usage_notes.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Nấu cả bữa từng bước (prototype `MealCookStep`): chặng Sơ chế chung, tab món, bước đứng bếp của
/// món đang xem, đồng hồ của mọi món, chặng Lưu ý cuối bữa. Nút chính: "Xong sơ chế" ở chặng Sơ
/// chế, "Xong món n" ở bước cuối món, "Xong cả bữa" chỉ ở chặng Lưu ý. Sơ chế chưa tick đủ, còn món
/// chưa xong thì hỏi lại trước khi đi tiếp.
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

    // Chỉ hỏi lại khi còn việc chưa làm: sơ chế chưa tick đủ, còn món khác chưa xong.
    Future<void> finishPrep() async {
      if (state.prepFinished) return viewModel.next();
      if (await showCookConfirmSheet(
        context,
        title: CookStrings.prepConfirmTitle,
        body: CookStrings.prepConfirmBody(state.prepDoneCount, state.prepTotal),
        confirmLabel: CookStrings.finishPrep,
        cancelLabel: CookStrings.keepPrepping,
      )) {
        await viewModel.finishPrep();
      }
    }

    Future<void> finish() async {
      final router = GoRouter.of(context);
      final unfinished = state.unfinished;
      if (unfinished.isNotEmpty &&
          !await showCookConfirmSheet(
            context,
            title: CookStrings.mealConfirmTitle,
            body: CookStrings.mealConfirmBody(unfinished),
            confirmLabel: CookStrings.confirmFinishMeal,
            cancelLabel: CookStrings.keepCooking,
          )) {
        return;
      }
      await viewModel.finishMeal();
      router.pushReplacement(mealCookDoneLocation);
    }

    // Nhãn cố định, không ghi tên món: tên dài không làm tràn nút.
    final Widget nextButton;
    if (state.inPrep) {
      nextButton = _NextButton(label: CookStrings.finishPrep, onPressed: finishPrep);
    } else if (state.inNotes) {
      nextButton = AppButton(
        label: CookStrings.finishMeal,
        icon: AppIcons.check,
        size: AppButtonSize.lg,
        block: true,
        onPressed: finish,
      );
    } else if (!state.isLastStep) {
      nextButton = _NextButton(label: CookStrings.nextStep, onPressed: viewModel.next);
    } else {
      nextButton = _NextButton(
        label: CookStrings.finishDish(state.current + 1),
        onPressed: viewModel.next,
      );
    }

    final timers = StepTimers(
      timers: [
        for (final (dish, step) in state.timedSteps)
          StepTimerSlot(
            key: ValueKey(cookTimerKey(dish, step)),
            visible: state.showsTimer(dish, step),
            seconds: state.dishes[dish].recipe.steps[step].timerSeconds!,
            endAt: state.timerEnds[cookTimerKey(dish, step)],
            label: CookStrings.mealTimerLabel(
              state.dishes[dish].recipe.name,
              state.stepNumber(dish, step),
            ),
            clock: viewModel.clock,
            onStatusChange: (status) => viewModel.timerChanged(dish, step, status),
          ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepHeader(
              step: state.index + 1,
              total: state.steps.length,
              done: state.index + 1,
              title: state.inPrep
                  ? CookStrings.mealPrepStageTitle(state.meal)
                  : state.inNotes
                  ? CookStrings.mealNotesStageTitle(state.meal)
                  : CookStrings.mealStepTitle(state.meal, state.current + 1, state.dishes.length),
              showProgress: false,
              below: _StageTabs(
                state: state,
                onPrep: viewModel.showPrep,
                onNotes: viewModel.showNotes,
                onSelect: viewModel.selectDish,
              ),
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
              child: state.inPrep || state.inNotes
                  ? StepBody.custom(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s4,
                        AppSpacing.s5,
                        AppSpacing.s4,
                        AppSpacing.s4,
                      ),
                      timers: timers,
                      child: state.inPrep
                          ? _PrepStage(state: state, onToggle: viewModel.togglePrep)
                          : UsageNotes(
                              groups: [for (final n in state.notes) (dish: n.dish, notes: n.notes)],
                            ),
                    )
                  : StepBody(
                      label: CookStrings.mealStepLabel(
                        recipe.name,
                        state.index + 1,
                        state.steps.length,
                      ),
                      text: state.step.text,
                      timers: timers,
                    ),
            ),
            if (state.inNotes) CheerLine(text: state.cheer),
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

/// Nút chính lg chiếm hết chỗ.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      AppButton(label: label, size: AppButtonSize.lg, block: true, onPressed: onPressed);
}

/// Chặng "Sơ chế cả bữa": nhãn kèm phút, câu mẹo, danh sách việc, dòng gợi ý vào nấu luôn.
class _PrepStage extends StatelessWidget {
  const _PrepStage({required this.state, required this.onToggle});

  final MealStepState state;
  final ValueChanged<PrepItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.s2);
    final minutes = state.prepMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s3,
      children: [
        Padding(
          padding: inset,
          child: Semantics(
            header: true,
            child: Text(
              minutes > 0 ? CookStrings.prepStageLabel(minutes) : CookStrings.prepStageLabelNoTime,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 13 * 0.04,
                color: colors.chiliDeep,
              ),
            ),
          ),
        ),
        Padding(
          padding: inset,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: CookStrings.prepTipLead,
                  style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600,
                    color: colors.chiliDeep,
                  ),
                ),
                const TextSpan(text: CookStrings.prepTip),
              ],
            ),
            // Prototype 14/20 nghiêng 400, `inkMuted`.
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 20 / 14,
              fontStyle: FontStyle.italic,
              color: colors.inkMuted,
            ),
          ),
        ),
        RowsBox(
          rows: [
            for (final item in state.prep)
              PrepTaskTile(item: item, checkedOf: state.checkedOf, onToggle: onToggle),
          ],
        ),
        Padding(
          padding: inset,
          child: Text(
            CookStrings.prepSkipHint,
            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Dải chặng: tab "Sơ chế" (khi bữa có việc sơ chế), tab từng món, tab "Lưu ý" cuối; cuộn ngang
/// khi nhiều món, tab món rộng tối thiểu 112, chia đều chỗ còn lại.
class _StageTabs extends StatefulWidget {
  const _StageTabs({
    required this.state,
    required this.onPrep,
    required this.onNotes,
    required this.onSelect,
  });

  final MealStepState state;
  final VoidCallback onPrep;
  final VoidCallback onNotes;
  final ValueChanged<int> onSelect;

  @override
  State<_StageTabs> createState() => _StageTabsState();
}

class _StageTabsState extends State<_StageTabs> {
  /// Bề rộng tab Sơ chế, tab Lưu ý.
  static const _prepWidth = 88.0;
  static const _minDishWidth = 112.0;

  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(_StageTabs old) {
    super.didUpdateWidget(old);
    if (old.state.inPrep != widget.state.inPrep ||
        old.state.inNotes != widget.state.inNotes ||
        old.state.current != widget.state.current) {
      _revealSelected();
    }
  }

  /// Tab đang chọn nằm ngoài màn (bữa nhiều món) thì cuộn tới.
  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _selectedKey.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final colors = context.colors;
    return Semantics(
      container: true,
      label: CookStrings.mealDishes,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.s2;
          final count = state.dishes.length;
          final room =
              constraints.maxWidth -
              AppSpacing.s3 -
              (state.hasPrep ? _prepWidth + gap : 0) -
              (_prepWidth + gap) -
              gap * (count - 1);
          final dishWidth = math.max(_minDishWidth, room / count);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: AppSpacing.s3),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  if (state.hasPrep)
                    SizedBox(
                      key: state.inPrep ? _selectedKey : null,
                      width: _prepWidth,
                      child: _StageTab(
                        label: CookStrings.prepTab,
                        selected: state.inPrep,
                        finished: state.prepFinished,
                        progress: state.prepFinished
                            ? CookStrings.finish
                            : CookStrings.prepProgress(state.prepDoneCount, state.prepTotal),
                        bar: _FractionBar(
                          value: state.prepTotal == 0 ? 0 : state.prepDoneCount / state.prepTotal,
                          color: colors.chili,
                          track: colors.line,
                        ),
                        onTap: widget.onPrep,
                      ),
                    ),
                  for (final (i, dish) in state.dishes.indexed)
                    SizedBox(
                      key: !state.inPrep && !state.inNotes && i == state.current
                          ? _selectedKey
                          : null,
                      width: dishWidth,
                      child: _dishTab(context, i, dish.recipe.name),
                    ),
                  SizedBox(
                    key: state.inNotes ? _selectedKey : null,
                    width: _prepWidth,
                    child: _StageTab(
                      label: CookStrings.notesTab,
                      selected: state.inNotes,
                      finished: state.allFinished,
                      progress: CookStrings.notesTabHint,
                      bar: _FractionBar(
                        value: state.finished.length / state.dishes.length,
                        color: colors.chili,
                        track: colors.line,
                      ),
                      onTap: widget.onNotes,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dishTab(BuildContext context, int i, String name) {
    final state = widget.state;
    final colors = context.colors;
    final steps = state.stepsOf(i).length;
    final position = state.positions[i];
    final selected = !state.inPrep && !state.inNotes && i == state.current;
    final finished = state.finished.contains(i);
    final started = selected || position > 0;
    return _StageTab(
      label: CookStrings.dishTab(i + 1, name),
      selected: selected,
      finished: finished,
      progress: finished
          ? CookStrings.finish
          : started
          ? CookStrings.stepOf(position + 1, steps)
          : CookStrings.dishSteps(steps),
      bar: Row(
        spacing: 3,
        children: [
          for (var k = 0; k < steps; k++)
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: finished || (k <= position && started) ? colors.chili : colors.line,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
            ),
        ],
      ),
      onTap: () => widget.onSelect(i),
    );
  }
}

/// Thanh tiến độ 4px của tab Sơ chế: phần đã xong tô [color].
class _FractionBar extends StatelessWidget {
  const _FractionBar({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: Container(
        height: 4,
        color: track,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}

/// Một tab trong dải chặng: tên (dấu check khi xong, cắt "…"), thanh tiến độ, "Bước 2/4" / "Xong".
class _StageTab extends StatelessWidget {
  const _StageTab({
    required this.label,
    required this.selected,
    required this.finished,
    required this.progress,
    required this.bar,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool finished;
  final String progress;
  final Widget bar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(color: colors.ink),
                        ),
                      ),
                    ],
                  ),
                  ExcludeSemantics(child: bar),
                  Text(
                    progress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
