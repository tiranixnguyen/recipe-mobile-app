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
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Đã lưu v2 — tab Món ăn / Bữa ăn, nhấn giữ kéo vào thùng rác để bỏ lưu.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _tabWord =>
      _tabs.index == 0 ? DiscoverStrings.savedTabWord : DiscoverStrings.savedMealTabWord;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(savedViewModelProvider);

    return switch (state) {
      AsyncData(:final value) => _Body(
        state: value,
        tabs: _tabs,
        searchCtrl: _searchCtrl,
        tabWord: _tabWord,
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
    required this.tabs,
    required this.searchCtrl,
    required this.tabWord,
    required this.onUnsave,
  });

  final SavedState state;
  final TabController tabs;
  final TextEditingController searchCtrl;
  final String tabWord;
  final Future<void> Function(BuildContext, UnsaveOutcome) onUnsave;

  /// Mẹo chỉ hiện khi tab đang mở có ít nhất một thứ sau khi lọc (như prototype).
  bool _showTip() {
    if (tabs.index == 0) return state.filteredRecipes.isNotEmpty;
    return state.filteredMeals.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasAny = state.recipes.isNotEmpty || state.meals.isNotEmpty;

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
                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  child: _TabBar(tabs: tabs, state: state),
                ),
                const SizedBox(height: AppSpacing.s3),
                // Search field — chỉ hiện khi có ít nhất một thứ đã lưu
                if (hasAny)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                    child: _SearchField(
                      controller: searchCtrl,
                      onChanged: (q) => ref.read(savedViewModelProvider.notifier).setQuery(q),
                      onClear: () {
                        searchCtrl.clear();
                        ref.read(savedViewModelProvider.notifier).clearQuery();
                      },
                    ),
                  ),
                if (hasAny) const SizedBox(height: AppSpacing.s3),
                // Content
                Expanded(
                  child: TabBarView(
                    controller: tabs,
                    children: [
                      _RecipesTab(state: state, onUnsave: onUnsave),
                      _MealsTab(state: state, onUnsave: onUnsave),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Thùng rác: xuất hiện khi đang kéo
          _TrashOverlay(onUnsave: onUnsave),
          // Mẹo: chỉ khi tab đang mở có thứ để kéo, ẩn khi đang kéo
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
                          text: DiscoverStrings.savedDragTipText(tabWord),
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
// Tab bar (pill style)
// ---------------------------------------------------------------------------

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs, required this.state});

  final TabController tabs;
  final SavedState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.line,
        borderRadius: AppRadius.pillAll,
      ),
      child: TabBar(
        controller: tabs,
        indicator: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: AppRadius.pillAll,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.label,
        labelColor: colors.ink,
        unselectedLabelColor: colors.inkMuted,
        tabs: [
          Tab(text: DiscoverStrings.savedTabRecipes(state.recipes.length)),
          Tab(text: DiscoverStrings.savedTabMeals(state.meals.length)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search field
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.outline),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 20, color: colors.inkMuted),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: DiscoverStrings.savedSearchPlaceholder,
                hintStyle: AppTextStyles.body.copyWith(color: colors.inkMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.body.copyWith(color: colors.ink),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: Icon(AppIcons.close, size: 18, color: colors.inkMuted),
                    tooltip: DiscoverStrings.clearQuery,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Món ăn
// ---------------------------------------------------------------------------

class _RecipesTab extends ConsumerWidget {
  const _RecipesTab({required this.state, required this.onUnsave});

  final SavedState state;
  final Future<void> Function(BuildContext, UnsaveOutcome) onUnsave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.recipes.isEmpty) {
      return Center(
        child: EmptyState(
          icon: AppIcons.bookmark,
          title: DiscoverStrings.savedEmptyTitle,
          message: DiscoverStrings.savedEmptyBody,
          actionLabel: DiscoverStrings.savedEmptyRecipesAction,
          onAction: () => context.go(searchLocation()),
        ),
      );
    }
    if (state.filteredRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            DiscoverStrings.savedNoMatch(state.query, DiscoverStrings.savedTabWord),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: context.colors.inkMuted),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s1,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.s3,
        mainAxisSpacing: AppSpacing.s3,
        childAspectRatio: 0.72,
      ),
      itemCount: state.filteredRecipes.length,
      itemBuilder: (context, i) {
        final item = state.filteredRecipes[i];
        return _DraggableRecipeCard(
          item: item,
          onUnsave: (outcome) => onUnsave(context, outcome),
          onTap: () => context.push(recipeLocation(item.recipe.id)),
          onAction: () async {
            final vm = ref.read(savedViewModelProvider.notifier);
            final outcome = await vm.unsaveRecipe(item.recipe);
            if (context.mounted) await onUnsave(context, outcome);
          },
        );
      },
    );
  }
}

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
        child: RecipeCard(
          title: item.recipe.name,
          minutes: item.recipe.minutes,
          servings: item.recipe.servings,
          tool: item.recipe.tools.firstOrNull?.shortLabel,
          imageAsset: item.recipe.imageAsset,
          badge: item.availability == null
              ? null
              : AvailabilityBadge(missing: item.availability!.missing),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Bữa ăn
// ---------------------------------------------------------------------------

class _MealsTab extends ConsumerWidget {
  const _MealsTab({required this.state, required this.onUnsave});

  final SavedState state;
  final Future<void> Function(BuildContext, UnsaveOutcome) onUnsave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.meals.isEmpty) {
      return Center(
        child: EmptyState(
          icon: AppIcons.bookmark,
          title: DiscoverStrings.savedEmptyMealsTitle,
          message: DiscoverStrings.savedEmptyMealsBody,
          actionLabel: DiscoverStrings.savedEmptyMealsAction,
          onAction: () => context.go(todayPrefsLocation),
        ),
      );
    }
    if (state.filteredMeals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            DiscoverStrings.savedNoMatch(state.query, DiscoverStrings.savedMealTabWord),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: context.colors.inkMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s1,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      itemCount: state.filteredMeals.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, i) {
        final item = state.filteredMeals[i];
        final name = mealDisplayName(item);
        return _DraggableMealCard(
          item: item,
          onUnsave: (outcome) => onUnsave(context, outcome),
          onTap: () => context.go(todayPrefsLocation),
          onAction: () async {
            final vm = ref.read(savedViewModelProvider.notifier);
            final outcome = await vm.unsaveMeal(item);
            if (context.mounted) await onUnsave(context, outcome);
          },
          name: name,
        );
      },
    );
  }
}

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
      semanticsActionLabel: DiscoverStrings.savedMealUnsaveAction,
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
              // Mosaic
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
              // Text info
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
        // IgnorePointer khi không kéo: AnimatedSlide dịch chuyển nhưng giữ hit-test cũ,
        // nên cần IgnorePointer để không chặn tap trên nội dung.
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
