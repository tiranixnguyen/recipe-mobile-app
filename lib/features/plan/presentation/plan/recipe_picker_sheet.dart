import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/recipe_picker_view_model.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Mở sheet chọn món cho [meal]; trả id món đã chọn, null nếu đóng.
Future<String?> showRecipePicker(BuildContext context, Meal meal) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: RecipePickerSheet(meal: meal)),
);

class RecipePickerSheet extends ConsumerWidget {
  const RecipePickerSheet({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final provider = recipePickerViewModelProvider(meal);
    final state = ref.watch(provider);
    const side = EdgeInsets.symmetric(horizontal: AppSpacing.s4);

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Text(text, style: AppTextStyles.label.copyWith(color: colors.inkMuted)),
    );

    Widget row(Recipe recipe) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s2),
      child: RecipeRow(
        title: recipe.name,
        meta: recipeMeta(recipe),
        imageAsset: recipe.imageAsset,
        thumbSize: 48,
        onTap: () => Navigator.of(context).pop(recipe.id),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: side,
          child: Text(
            PlanStrings.pickTitle(meal.label),
            style: AppTextStyles.title.copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Padding(
          padding: side,
          child: SearchField(
            placeholder: PlanStrings.pickSearch,
            onChanged: ref.read(provider.notifier).search,
          ),
        ),
        Expanded(
          child: switch (state) {
            AsyncData(value: (saved: [], all: [])) => Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Text(
                PlanStrings.pickEmpty,
                style: AppTextStyles.body.copyWith(color: colors.inkMuted),
              ),
            ),
            AsyncData(value: (:final saved, :final all)) => ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              children: [
                if (saved.isNotEmpty) ...[
                  sectionLabel(PlanStrings.pickSaved),
                  for (final recipe in saved) row(recipe),
                ],
                if (all.isNotEmpty) ...[
                  sectionLabel(PlanStrings.pickAll),
                  for (final recipe in all) row(recipe),
                ],
              ],
            ),
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
      ],
    );
  }
}
