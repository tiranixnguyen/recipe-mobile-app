import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Đã lưu — danh sách phẳng Món ăn + Bữa ăn, nhấn giữ kéo vào thùng rác để bỏ lưu.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(savedViewModelProvider);

    return switch (state) {
      AsyncData(:final value) => _Body(
        state: value,
        searchCtrl: _searchCtrl,
        onUnsave: _unsave,
      ),
      AsyncError() => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text(
              DiscoverStrings.loadError,
              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
            ),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  Future<void> _unsave(BuildContext ctx, UnsaveOutcome outcome) async {
    final vm = ref.read(savedViewModelProvider.notifier);
    AppSnackbar.show(
      ctx,
      DiscoverStrings.savedUnsaved(outcome.name),
      action: SnackAction(DiscoverStrings.savedUndo, () => vm.undo(outcome)),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (when data loaded)
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.searchCtrl,
    required this.onUnsave,
  });

  final SavedState state;
  final TextEditingController searchCtrl;
  final Future<void> Function(BuildContext, UnsaveOutcome) onUnsave;

  bool _showTip() => state.filteredRecipes.isNotEmpty || state.filteredMeals.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasAny = state.recipes.isNotEmpty || state.meals.isNotEmpty;
    final allEmpty = state.recipes.isEmpty && state.meals.isEmpty;
    final filteredEmpty = state.filteredRecipes.isEmpty && state.filteredMeals.isEmpty;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s3,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      DiscoverStrings.saved,
                      style: AppTextStyles.title.copyWith(color: colors.ink),
                    ),
                  ),
                ),
                if (hasAny) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    child: SearchField(
                      controller: searchCtrl,
                      placeholder: DiscoverStrings.savedSearchPlaceholder,
                      label: DiscoverStrings.savedSearchLabel,
                      onChanged: (q) => ref.read(savedViewModelProvider.notifier).setQuery(q),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
                // Content
                Expanded(
                  child: allEmpty
                      ? Center(
                          child: EmptyState(
                            icon: AppIcons.bookmark,
                            title: DiscoverStrings.savedEmptyTitle,
                            message: DiscoverStrings.savedEmptyBody,
                            actionLabel: DiscoverStrings.savedEmptyRecipesAction,
                            onAction: () => context.go(searchLocation()),
                          ),
                        )
                      : filteredEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s4),
                            child: Text(
                              DiscoverStrings.savedNoMatch(state.query),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                            ),
                          ),
                        )
                      : _SavedList(state: state, onUnsave: onUnsave),
                ),
              ],
            ),
          ),
          // Thùng rác: xuất hiện khi đang kéo
          _TrashOverlay(onUnsave: onUnsave),
          // Mẹo: ẩn khi danh sách trống hoặc đang kéo
          if (_showTip())
            ValueListenableBuilder<Object?>(
              valueListenable: AppDrag.active,
              builder: (context, dragging, _) => dragging == null
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          AppSpacing.s4,
                          AppSpacing.s4,
                          AppSpacing.s8 + AppSpacing.s4,
                        ),
                        child: TipBubble(
                          id: savedDragTip,
                          text: DiscoverStrings.savedDragTipText(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flat list: filteredRecipes rồi filteredMeals
// ---------------------------------------------------------------------------

class _SavedList extends ConsumerWidget {
  const _SavedList({required this.state, required this.onUnsave});

  final SavedState state;
  final Future<void> Function(BuildContext, UnsaveOutcome) onUnsave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = state.filteredRecipes;
    final meals = state.filteredMeals;
    final total = recipes.length + meals.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        0,
        AppSpacing.s4,
        AppSpacing.s6,
      ),
      itemCount: total,
      itemBuilder: (context, i) {
        if (i < recipes.length) {
          final item = recipes[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: _DraggableRecipeCard(
              item: item,
              onUnsave: (outcome) => onUnsave(context, outcome),
              onTap: () => context.push(recipeLocation(item.recipe.id)),
              onAction: () async {
                final vm = ref.read(savedViewModelProvider.notifier);
                final outcome = await vm.unsaveRecipe(item.recipe);
                if (context.mounted) await onUnsave(context, outcome);
              },
            ),
          );
        }
        final item = meals[i - recipes.length];
        final name = mealDisplayName(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
          child: _DraggableMealCard(
            item: item,
            name: name,
            onUnsave: (outcome) => onUnsave(context, outcome),
            onTap: () => context.go(todayPrefsLocation),
            onAction: () async {
              final vm = ref.read(savedViewModelProvider.notifier);
              final outcome = await vm.unsaveMeal(item);
              if (context.mounted) await onUnsave(context, outcome);
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe card (horizontal)
// ---------------------------------------------------------------------------

class _DraggableRecipeCard extends ConsumerWidget {
  const _DraggableRecipeCard({
    required this.item,
    required this.onUnsave,
    required this.onTap,
    required this.onAction,
  });

  final SavedRecipeItem item;
  final void Function(UnsaveOutcome) onUnsave;
  final VoidCallback onTap;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HoldDraggable<SavedRecipeItem>(
      data: item,
      liftedRadius: AppRadius.mdAll,
      semanticsActionLabel: DiscoverStrings.savedRecipeUnsaveAction,
      onSemanticsAction: onAction,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.delete): onAction,
        },
        child: _RecipeCard(item: item, onTap: onTap),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.item, required this.onTap});

  final SavedRecipeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = item.recipe;
    final meta = DiscoverStrings.recipeMeta(
      recipe.minutes,
      recipe.servings,
      recipe.tools.firstOrNull?.shortLabel,
    );

    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: recipe.imageAsset.isNotEmpty
                      ? Image.asset(recipe.imageAsset, fit: BoxFit.cover)
                      : ColoredBox(
                          color: colors.line,
                          child: Center(
                            child: Icon(AppIcons.bowl, size: 32, color: colors.inkMuted),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: AppTextStyles.body.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      meta,
                      style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                    ),
                    if (item.availability != null) ...[
                      const SizedBox(height: AppSpacing.s1),
                      AvailabilityBadge(missing: item.availability!.missing),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal card (horizontal, preserved from v2)
// ---------------------------------------------------------------------------

class _DraggableMealCard extends ConsumerWidget {
  const _DraggableMealCard({
    required this.item,
    required this.onUnsave,
    required this.onTap,
    required this.onAction,
    required this.name,
  });

  final SavedMealItem item;
  final void Function(UnsaveOutcome) onUnsave;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HoldDraggable<SavedMealItem>(
      data: item,
      liftedRadius: AppRadius.mdAll,
      semanticsActionLabel: DiscoverStrings.savedUnsaveAction,
      onSemanticsAction: onAction,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.delete): onAction,
        },
        child: _MealCard(item: item, name: name, onTap: onTap),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.item, required this.name, required this.onTap});

  final SavedMealItem item;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalMinutes = item.recipes.fold(0, (sum, r) => sum + r.minutes);
    final servings = item.meal.servings;
    final meta = DiscoverStrings.recipeMeta(totalMinutes, servings, null);

    return Material(
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: MealMosaic(
                  size: 96,
                  radius: AppRadius.smAll,
                  dishes: [
                    for (final r in item.recipes) MosaicDish(r.name, r.imageAsset),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      meta,
                      style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                    ),
                    if (item.meal.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s1),
                      Wrap(
                        spacing: AppSpacing.s1,
                        runSpacing: AppSpacing.s1,
                        children: [
                          for (final tag in item.meal.tags) _TagChip(label: tag.label),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 2),
      decoration: BoxDecoration(
        color: colors.chiliSoft,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: colors.chiliDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trash overlay — xuất hiện khi đang kéo thẻ món hoặc bữa
// ---------------------------------------------------------------------------

class _TrashOverlay extends ConsumerWidget {
  const _TrashOverlay({required this.onUnsave});

  final Future<void> Function(BuildContext, UnsaveOutcome) onUnsave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<Object?>(
      valueListenable: AppDrag.active,
      builder: (context, dragging, _) {
        final isDragging = dragging is SavedRecipeItem || dragging is SavedMealItem;
        return IgnorePointer(
          ignoring: !isDragging,
          child: AnimatedSlide(
            offset: isDragging ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DragTarget<Object>(
                onWillAcceptWithDetails: (details) =>
                    details.data is SavedRecipeItem || details.data is SavedMealItem,
                onAcceptWithDetails: (details) async {
                  HapticFeedback.selectionClick();
                  final vm = ref.read(savedViewModelProvider.notifier);
                  final UnsaveOutcome outcome;
                  if (details.data case final SavedRecipeItem item) {
                    outcome = await vm.unsaveRecipe(item.recipe);
                  } else if (details.data case final SavedMealItem item) {
                    outcome = await vm.unsaveMeal(item);
                  } else {
                    return;
                  }
                  await ref.read(tipsSeenProvider.notifier).markSeen(savedDragTip);
                  if (context.mounted) await onUnsave(context, outcome);
                },
                builder: (context, candidates, _) {
                  final over = candidates.isNotEmpty;
                  return _TrashBar(danger: over);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrashBar extends StatelessWidget {
  const _TrashBar({required this.danger});

  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      height: 128,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.line)),
        boxShadow: const [
          BoxShadow(color: Color(0x1F140E0A), blurRadius: 16, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: danger ? colors.danger : colors.line,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.trash,
              size: 28,
              color: danger ? Colors.white : colors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.s1 + 2),
          Text(
            danger ? DiscoverStrings.savedTrashDanger : DiscoverStrings.savedTrashHint,
            style: AppTextStyles.caption.copyWith(
              color: danger ? colors.dangerInk : colors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
