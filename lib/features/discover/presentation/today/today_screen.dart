import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
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
                          'Bữa ${state.meal.label.toLowerCase()} · gợi ý cho bạn',
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
                            label: 'Bữa ${meal.label.toLowerCase()}',
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
                          ('Dưới 15 phút', 15),
                          ('Dưới 30 phút', 30),
                          ('Thoải mái', null),
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
                  ...switch (suggestions) {
                    AsyncData(value: final List<Recipe> recipes) when recipes.isEmpty => [
                      Text(
                        'Chưa có món phù hợp. Bạn thử chọn thời gian khác nhé.',
                        style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                      ),
                    ],
                    AsyncData(value: final List<Recipe> recipes) => [
                      Builder(
                        builder: (context) {
                          final main = recipes[state.index % recipes.length];
                          final alternatives = recipes.where((r) => r.id != main.id).take(2);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MainRecipe(recipe: main),
                              const SizedBox(height: AppSpacing.s3),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: vm.toggleReasons,
                                      child: const Text('Không thích'),
                                    ),
                                  ),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: vm.next,
                                      icon: const Icon(AppIcons.shuffle),
                                      label: const Text('Đổi món'),
                                    ),
                                  ),
                                ],
                              ),
                              if (state.showReasons)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                                  child: Wrap(
                                    spacing: AppSpacing.s2,
                                    runSpacing: AppSpacing.s2,
                                    children: [
                                      for (final reason in DislikeReason.values)
                                        ActionChip(
                                          label: Text(reason.label),
                                          onPressed: () => vm.dislike(main.id, reason),
                                        ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.s4),
                              Text(
                                'Hoặc thử',
                                style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              for (final recipe in alternatives)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                                  child: RecipeRow(
                                    title: recipe.name,
                                    imageAsset: recipe.imageAsset,
                                    meta: '${recipe.minutes} phút',
                                    onTap: () => context.push(recipeLocation(recipe.id)),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    AsyncError() => [
                      Text(
                        DiscoverStrings.loadError,
                        style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                      ),
                    ],
                    _ => [const Center(child: CircularProgressIndicator())],
                  },
                ],
              ),
            ),
            if (suggestions case AsyncData(value: final List<Recipe> recipes)
                when recipes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Nấu món này',
                    onPressed: () =>
                        context.push(recipeLocation(recipes[state.index % recipes.length].id)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MainRecipe extends ConsumerWidget {
  const _MainRecipe({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final availability = ref.watch(availabilityProvider(recipe));
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
              child: RecipeCover(imageAsset: recipe.imageAsset),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: AppTextStyles.title.copyWith(color: colors.ink)),
                  Text(
                    '${recipe.minutes} phút · ${recipe.servings} người',
                    style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                  ),
                  Text(
                    availability == null
                        ? 'Món phù hợp với bữa bạn chọn'
                        : availability.missing.isEmpty
                        ? 'Bạn có đủ nguyên liệu cho món này'
                        : 'Bạn còn thiếu ${availability.missing.length} nguyên liệu',
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
