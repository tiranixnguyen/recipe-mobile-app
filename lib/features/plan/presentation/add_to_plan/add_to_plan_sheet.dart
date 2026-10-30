import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/inline_banner.dart';
import 'package:recipe_mobile_app/core/widgets/serving_stepper.dart';
import 'package:recipe_mobile_app/features/plan/presentation/add_to_plan/add_to_plan_view_model.dart';
import 'package:recipe_mobile_app/features/plan/routes.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Mở sheet "Thêm vào thực đơn" cho [recipe] (prototype `AddToPlan`, từ Chi tiết món).
///
/// Thêm xong thì chuyển sang tab Thực đơn, mở ngày và bữa vừa thêm, và trả true; trả false khi
/// người dùng huỷ hoặc đóng sheet. [context] phải nằm dưới `GoRouter`.
Future<bool> showAddToPlanSheet(BuildContext context, Recipe recipe) =>
    showAddMealToPlanSheet(context, [recipe]);

/// Như [showAddToPlanSheet] nhưng thêm cả bữa [recipes] vào một bữa (Hôm nay ăn gì, Đã lưu).
Future<bool> showAddMealToPlanSheet(BuildContext context, List<Recipe> recipes) async {
  assert(recipes.isNotEmpty, 'Cần ít nhất một món');
  final added = await showModalBottomSheet<({DateTime date, Meal meal})>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => AddToPlanSheet(recipeIds: [for (final r in recipes) r.id]),
  );
  if (added == null) return false;
  if (context.mounted) goToPlanDay(context, added.date, meal: added.meal);
  return true;
}

class AddToPlanSheet extends ConsumerWidget {
  const AddToPlanSheet({super.key, required this.recipeIds});

  final List<String> recipeIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final provider = addToPlanViewModelProvider(addToPlanKey(recipeIds));
    final state = ref.watch(provider);

    return switch (state) {
      AsyncData(:final value) => _Content(state: value, viewModel: ref.read(provider.notifier)),
      AsyncError() => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s6),
        child: Text(
          PlanStrings.addNotFound,
          style: AppTextStyles.body.copyWith(color: colors.inkMuted),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.s6),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.viewModel});

  final AddToPlanState state;
  final AddToPlanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final joinText = state.joinText;

    Widget sectionLabel(String text) =>
        Text(text, style: AppTextStyles.label.copyWith(color: colors.ink));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.s4,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  PlanStrings.addTitle,
                  style: AppTextStyles.title.copyWith(color: colors.ink),
                ),
              ),
              Text(
                state.subline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s2,
            children: [
              sectionLabel(PlanStrings.addDays),
              Row(
                spacing: AppSpacing.s1,
                children: [
                  for (final day in state.days)
                    Expanded(
                      child: _DayRadio(day: day, onTap: () => viewModel.pickDay(day.date)),
                    ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s2,
            children: [
              sectionLabel(PlanStrings.addMeal),
              for (final meal in Meal.values)
                _MealRadio(
                  meal: meal,
                  summary: state.mealSummaries[meal]!,
                  selected: meal == state.meal,
                  onTap: () => viewModel.pickMeal(meal),
                ),
              if (joinText != null)
                Semantics(
                  liveRegion: true,
                  child: InlineBanner(text: joinText, kind: BannerKind.success),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  PlanStrings.addServings,
                  style: AppTextStyles.button.copyWith(color: colors.ink),
                ),
              ),
              ServingStepper(
                value: state.servings,
                min: AddToPlanState.minServings,
                max: AddToPlanState.maxServings,
                onChanged: viewModel.setServings,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: Row(
              spacing: AppSpacing.s3,
              children: [
                SizedBox(
                  width: 96,
                  child: AppButton.secondary(
                    label: PlanStrings.cancel,
                    block: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: AppButton(
                    label: state.confirmLabel,
                    block: true,
                    onPressed: () async {
                      final added = await viewModel.confirm();
                      // Trả ngày và bữa vừa thêm để mở đúng chỗ đó trên Thực đơn.
                      if (context.mounted) Navigator.of(context).pop(added);
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

/// Ô ngày cao 56: đang chọn nền `chili` chữ trắng.
class _DayRadio extends StatelessWidget {
  const _DayRadio({required this.day, required this.onTap});

  final DayOption day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = day.selected;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: day.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.chili : colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? colors.chili : colors.line),
          borderRadius: AppRadius.mdAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                day.short,
                // Chữ trắng trên nền `chili` như prototype.
                style: AppTextStyles.label.copyWith(color: selected ? Colors.white : colors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng chọn bữa: vòng radio, tên bữa, món đang có hoặc "Trống".
class _MealRadio extends StatelessWidget {
  const _MealRadio({
    required this.meal,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final Meal meal;
  final String summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ring = selected ? colors.chili : colors.outline;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${meal.label}, $summary',
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.chiliSoft : colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          side: selected
              ? BorderSide(color: colors.chili, width: 2)
              : BorderSide(color: colors.outline),
          borderRadius: AppRadius.mdAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.s2),
              child: Row(
                spacing: AppSpacing.s3,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ring, width: 2),
                    ),
                    child: selected
                        ? DecoratedBox(
                            decoration: BoxDecoration(color: colors.chili, shape: BoxShape.circle),
                            child: const SizedBox.square(dimension: 10),
                          )
                        : null,
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      meal.label,
                      style: AppTextStyles.button.copyWith(color: colors.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colors.inkMuted,
                      ),
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
