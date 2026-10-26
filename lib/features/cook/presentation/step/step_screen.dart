import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/step/step_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_step_widgets.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';

/// Nấu từng bước (prototype `CookStep`): mỗi màn một bước chữ lớn, hẹn giờ, sheet Nguyên liệu;
/// dưới cùng Bước trước / Bước tiếp, bước cuối là "Xong" sang Hoàn thành.
class StepScreen extends ConsumerWidget {
  const StepScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(stepViewModelProvider(recipeId))) {
      AsyncData(:final value) => _Step(state: value),
      AsyncError(error: RecipeNotFound()) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            title: CookStrings.notFoundTitle,
            message: CookStrings.notFoundBody,
            actionLabel: CookStrings.notFoundAction,
            onAction: () => context.go(discoverLocation),
          ),
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            CookStrings.loadError,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Step extends ConsumerWidget {
  const _Step({required this.state});

  final CookStepState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = state.recipe;
    final viewModel = ref.read(stepViewModelProvider(recipe.id).notifier);

    Future<void> finish() async {
      final router = GoRouter.of(context);
      await viewModel.finish();
      router.pushReplacement(cookDoneLocation(recipe.id));
    }

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
              onClose: () => context.canPop() ? context.pop() : context.go(discoverLocation),
              onIngredients: () => showStepIngredients(
                context,
                servings: state.servings,
                items: state.ingredients,
                basicSpices: state.basicSpices,
              ),
            ),
            Expanded(
              child: StepBody(label: CookStrings.stepLabel(state.index + 1), text: state.step.text),
            ),
            StepTimers(
              timers: [
                for (final i in state.timedSteps)
                  StepTimerSlot(
                    key: ValueKey(i),
                    visible: state.showsTimer(i),
                    seconds: state.steps[i].timerSeconds!,
                    label: CookStrings.timerLabel(i + 1),
                    clock: viewModel.clock,
                    onStatusChange: (status) => viewModel.timerChanged(i, status),
                  ),
              ],
            ),
            CookFooter(
              child: Row(
                spacing: AppSpacing.s3,
                children: [
                  // 1 : 1.4 như prototype.
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
                  Expanded(
                    flex: 7,
                    child: state.isLast
                        ? AppButton(
                            label: CookStrings.finish,
                            icon: AppIcons.check,
                            size: AppButtonSize.lg,
                            block: true,
                            onPressed: finish,
                          )
                        : AppButton(
                            label: CookStrings.nextStep,
                            size: AppButtonSize.lg,
                            block: true,
                            onPressed: viewModel.next,
                          ),
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
