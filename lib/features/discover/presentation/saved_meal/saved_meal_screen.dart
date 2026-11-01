import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved_meal/saved_meal_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Chi tiết một bữa đã lưu: ảnh ghép, các món, Thêm vào thực đơn, Bỏ lưu (kèm Hoàn tác).
///
/// Chưa có prototype; bố cục tối giản theo Chi tiết lần nấu, so lại khi sync `docs/design/`.
class SavedMealScreen extends ConsumerWidget {
  const SavedMealScreen({super.key, required this.mealKey});

  final String mealKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(savedMealViewModelProvider(mealKey))) {
      AsyncData(value: final entry?) => _SavedMeal(mealKey: mealKey, entry: entry),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            icon: AppIcons.bookmark,
            title: DiscoverStrings.savedMealNotFound,
            actionLabel: DiscoverStrings.savedMealBack,
            onAction: () => context.go(savedLocation()),
          ),
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            DiscoverStrings.loadError,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _SavedMeal extends ConsumerWidget {
  const _SavedMeal({required this.mealKey, required this.entry});

  final String mealKey;
  final SavedMealEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final vm = ref.read(savedMealViewModelProvider(mealKey).notifier);

    Future<void> unsave() async {
      final router = GoRouter.of(context);
      final outcome = await vm.unsave();
      if (outcome == null) return;
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(savedLocation());
      }
      if (context.mounted) {
        AppSnackbar.show(
          context,
          DiscoverStrings.savedUnsaved(outcome.name),
          action: SnackAction(DiscoverStrings.savedUndo, outcome.undo),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s4,
          AppSpacing.s6,
        ),
        children: [
          SizedBox(
            height: 168,
            child: MealMosaic(
              radius: AppRadius.mdAll,
              dishes: [for (final r in entry.recipes) MosaicDish(r.name, r.imageAsset)],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            entry.name,
            style: AppTextStyles.title.copyWith(color: colors.ink),
          ),
          Text(
            DiscoverStrings.savedMealMeta(entry.recipes.length, entry.meal.servings),
            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
          ),
          if (entry.meal.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s1,
              runSpacing: AppSpacing.s1,
              children: [for (final tag in entry.meal.tags) SavedTagChip(label: tag.label)],
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          Text(
            DiscoverStrings.savedMealDishes,
            style: AppTextStyles.subtitle.copyWith(color: colors.ink),
          ),
          for (final recipe in entry.recipes) ...[
            const SizedBox(height: AppSpacing.s2),
            RecipeRow(
              title: recipe.name,
              meta: DiscoverStrings.recipeMeta(
                recipe.minutes,
                recipe.servings,
                recipe.tools.firstOrNull?.shortLabel,
              ),
              imageAsset: recipe.imageAsset,
              onTap: () => context.push(recipeLocation(recipe.id)),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: DiscoverStrings.savedMealUnsave,
                  block: true,
                  onPressed: unsave,
                ),
              ),
              Expanded(
                child: AppButton(
                  label: DiscoverStrings.savedMealAddToPlan,
                  block: true,
                  onPressed: () =>
                      vm.addToPlan((dishes) => showAddMealToPlanSheet(context, dishes)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
