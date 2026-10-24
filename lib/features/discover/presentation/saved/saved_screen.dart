import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/save_button.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Đã lưu (prototype `Saved`).
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(savedViewModelProvider);
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
              child: Semantics(
                header: true,
                child: Text(
                  DiscoverStrings.saved,
                  style: AppTextStyles.title.copyWith(color: colors.ink),
                ),
              ),
            ),
            Expanded(
              child: switch (state) {
                AsyncData(value: []) => Center(
                  child: EmptyState(
                    icon: AppIcons.bookmark,
                    title: DiscoverStrings.savedEmptyTitle,
                    message: DiscoverStrings.savedEmptyBody,
                    actionLabel: DiscoverStrings.savedEmptyAction,
                    onAction: () => context.go(discoverLocation),
                  ),
                ),
                AsyncData(:final value) => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
                  itemBuilder: (context, i) {
                    final (:recipe, :availability) = value[i];
                    return RecipeCard(
                      title: recipe.name,
                      minutes: recipe.minutes,
                      servings: recipe.servings,
                      tool: recipe.tools.firstOrNull?.shortLabel,
                      imageAsset: recipe.imageAsset,
                      badge: availability == null
                          ? null
                          : AvailabilityBadge(missing: availability.missing),
                      action: SaveButton(recipeId: recipe.id),
                      onTap: () => context.push(recipeLocation(recipe.id)),
                    );
                  },
                ),
                AsyncError() => Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Text(
                    DiscoverStrings.loadError,
                    style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}
