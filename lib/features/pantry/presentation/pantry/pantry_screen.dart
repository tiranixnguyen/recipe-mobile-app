import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/strings.dart';

/// Tủ đồ (prototype `Pantry`): bật nguyên liệu đang có, xem món nấu được ngay và món thiếu ít.
class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(pantryViewModelProvider);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      PantryStrings.title,
                      style: AppTextStyles.title.copyWith(color: colors.ink),
                    ),
                  ),
                  Text(
                    PantryStrings.subtitle,
                    style: AppTextStyles.meta.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) => _Content(state: value),
                AsyncError() => Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Text(
                    PantryStrings.loadError,
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

class _Content extends ConsumerWidget {
  const _Content({required this.state});

  final PantryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(pantryViewModelProvider.notifier);
    void open(Recipe recipe) => context.push(recipeLocation(recipe.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      children: [
        for (final (i, (:group, :items)) in state.groups.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s3),
          Text(group.label, style: AppTextStyles.label.copyWith(color: colors.inkMuted)),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final ingredient in items)
                AppChip(
                  label: ingredient.name,
                  selected: state.have.contains(ingredient.id),
                  onTap: () => viewModel.toggle(ingredient.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s5),
        _SectionTitle(PantryStrings.ready, count: state.ready.length),
        const SizedBox(height: AppSpacing.s2),
        if (state.ready.isEmpty)
          Text(
            PantryStrings.noReady,
            style: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w400, color: colors.inkMuted),
          ),
        for (final recipe in state.ready)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: RecipeRow(
              title: recipe.name,
              meta: recipeMeta(recipe),
              imageAsset: recipe.imageAsset,
              thumbSize: 48,
              onTap: () => open(recipe),
            ),
          ),
        if (state.near.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          const _SectionTitle(PantryStrings.near),
          const SizedBox(height: AppSpacing.s2),
          for (final (:recipe, :availability) in state.near)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: RecipeRow(
                title: recipe.name,
                meta: AvailabilityBadge.missingLabel(availability.missing),
                emphasizeMeta: true,
                imageAsset: recipe.imageAsset,
                thumbSize: 48,
                onTap: () => open(recipe),
              ),
            ),
        ],
      ],
    );
  }
}

/// Tiêu đề khu "Nấu được ngay", kèm số món trên nền `herb` khi có [count].
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = this.count;
    return Semantics(
      header: true,
      child: Row(
        spacing: AppSpacing.s2,
        children: [
          Text(text, style: AppTextStyles.subtitle.copyWith(color: colors.ink)),
          if (count != null)
            DecoratedBox(
              decoration: BoxDecoration(color: colors.herb, borderRadius: AppRadius.smAll),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                child: Text(
                  '$count',
                  // Chữ trắng trên `herb` như `AvailabilityBadge`.
                  style: AppTextStyles.caption.copyWith(
                    height: 20 / 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
