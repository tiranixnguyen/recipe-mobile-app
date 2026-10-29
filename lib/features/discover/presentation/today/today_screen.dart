import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/domain/today.dart';
import 'package:recipe_mobile_app/features/discover/presentation/today/today_view_model.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(todayViewModelProvider.notifier).suggested();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(todayViewModelProvider);
    final suggestions = ref.watch(todayRecipesProvider);
    final vm = ref.read(todayViewModelProvider.notifier);
    // Giữ danh sách cũ khi đổi bữa/thời gian, chỉ hiện vòng xoay lúc chưa có dữ liệu lần nào.
    final recipes = suggestions.value;
    final pick = recipes == null ? null : todayPick(recipes, state.index);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                          DiscoverStrings.today,
                          style: AppTextStyles.title.copyWith(color: colors.ink),
                        ),
                        Text(
                          DiscoverStrings.todaySubtitle(state.meal.label.toLowerCase()),
                          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s4),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: AppSpacing.s2,
                      children: [
                        for (final meal in Meal.values)
                          AppChip(
                            label: DiscoverStrings.mealLabel(meal.label.toLowerCase()),
                            selected: state.meal == meal,
                            onTap: () => vm.setMeal(meal),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: AppSpacing.s2,
                      children: [
                        for (final (label, minutes) in [
                          (DiscoverStrings.quickUnder15, 15),
                          (DiscoverStrings.todayUnder30, 30),
                          (DiscoverStrings.todayAnyTime, null),
                        ])
                          AppChip(
                            label: label,
                            selected: state.maxMinutes == minutes,
                            onTap: () => vm.setMinutes(minutes),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  if (pick != null) ...[
                    _MainRecipe(recipe: pick.main, meal: state.meal),
                    const SizedBox(height: AppSpacing.s3),
                    Row(
                      spacing: AppSpacing.s2,
                      children: [
                        Expanded(
                          child: AppButton.ghost(
                            label: DiscoverStrings.todayDislike,
                            block: true,
                            onPressed: vm.toggleReasons,
                          ),
                        ),
                        Expanded(
                          child: AppButton.secondary(
                            label: DiscoverStrings.todayShuffle,
                            icon: AppIcons.shuffle,
                            block: true,
                            onPressed: vm.next,
                          ),
                        ),
                      ],
                    ),
                    if (state.showReasons)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s3),
                        child: _Reasons(
                          onPick: (reason) => vm.dislike(pick.main.id, reason),
                        ),
                      ),
                    if (pick.alternatives.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        DiscoverStrings.todayAlternatives,
                        style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      for (final recipe in pick.alternatives)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                          child: RecipeRow(
                            title: recipe.name,
                            imageAsset: recipe.imageAsset,
                            meta: DiscoverStrings.minutes(recipe.minutes),
                            onTap: () => context.push(recipeLocation(recipe.id)),
                          ),
                        ),
                    ],
                  ] else if (recipes != null)
                    Text(
                      DiscoverStrings.todayEmpty,
                      style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                    )
                  else if (suggestions.hasError)
                    Text(
                      DiscoverStrings.loadError,
                      style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            if (pick != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: AppButton(
                  label: DiscoverStrings.todayCook,
                  block: true,
                  onPressed: () => context.push(recipeLocation(pick.main.id)),
                ),
              ),
          ],
        ),
      ),
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
              style: AppTextStyles.caption.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w600,
              ),
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

class _MainRecipe extends ConsumerWidget {
  const _MainRecipe({required this.recipe, required this.meal});

  final Recipe recipe;
  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final missing = ref.watch(availabilityProvider(recipe))?.missing;
    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(recipeLocation(recipe.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 176,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecipeCover(imageAsset: recipe.imageAsset),
                  if (missing != null)
                    Positioned(
                      left: AppSpacing.s3,
                      top: AppSpacing.s3,
                      child: AvailabilityBadge(missing: missing),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.s1,
                children: [
                  Text(recipe.name, style: AppTextStyles.title.copyWith(color: colors.ink)),
                  Text(
                    DiscoverStrings.recipeMeta(
                      recipe.minutes,
                      recipe.servings,
                      recipe.tools.firstOrNull?.shortLabel,
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    todayReason(missing, meal),
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
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
