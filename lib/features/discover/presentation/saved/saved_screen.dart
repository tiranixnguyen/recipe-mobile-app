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
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/domain/saved.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Đã lưu v3: món và bữa chung một danh sách, nhóm theo thời gian như Lịch sử; nhấn giữ kéo vào
/// thùng rác để bỏ lưu. Mở với [highlightMeal] (Hôm nay ăn gì → Xem) thì bữa đó có ribbon "Mới thêm".
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key, this.highlightMeal});

  final String? highlightMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(savedViewModelProvider(highlightMeal))) {
      AsyncData(:final value) => _Body(state: value, highlightMeal: highlightMeal),
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
}

/// Bỏ lưu [entry] rồi báo snackbar có Hoàn tác.
Future<void> _unsave(BuildContext context, SavedViewModel vm, SavedEntry entry) async {
  final outcome = await vm.unsave(entry);
  if (!context.mounted) return;
  AppSnackbar.show(
    context,
    DiscoverStrings.savedUnsaved(outcome.name),
    action: SnackAction(DiscoverStrings.savedUndo, outcome.undo),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.highlightMeal});

  final SavedState state;
  final String? highlightMeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final vm = ref.read(savedViewModelProvider(highlightMeal).notifier);
    final groups = state.groups(vm.now());
    final hasAny = state.entries.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
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
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          DiscoverStrings.saved,
                          style: AppTextStyles.title.copyWith(color: colors.ink),
                        ),
                      ),
                      if (hasAny) ...[
                        Text(
                          DiscoverStrings.savedCount(state.entries.length),
                          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        SearchField(
                          placeholder: DiscoverStrings.savedSearchPlaceholder,
                          label: DiscoverStrings.savedSearchLabel,
                          onChanged: vm.setQuery,
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: !hasAny
                      ? Center(
                          child: EmptyState(
                            icon: AppIcons.bookmark,
                            title: DiscoverStrings.savedEmptyTitle,
                            message: DiscoverStrings.savedEmptyBody,
                            actionLabel: DiscoverStrings.savedEmptyRecipesAction,
                            onAction: () => context.go(searchLocation()),
                          ),
                        )
                      : groups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s4),
                            child: Text(
                              DiscoverStrings.savedNoMatch(state.query.trim()),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s4,
                            0,
                            AppSpacing.s4,
                            AppSpacing.s6,
                          ),
                          children: [
                            for (final (group, entries) in groups) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                                child: Text(
                                  _groupLabel(group),
                                  style: AppTextStyles.label.copyWith(color: colors.inkMuted),
                                ),
                              ),
                              for (final entry in entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                                  child: _DraggableEntry(
                                    entry: entry,
                                    isHighlight: state.isHighlight(entry),
                                    onUnsave: () => _unsave(context, vm, entry),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
          _TrashOverlay(vm: vm),
          // Mẹo: chỉ khi có thứ để kéo, ẩn khi đang kéo.
          if (groups.isNotEmpty)
            ValueListenableBuilder<Object?>(
              valueListenable: AppDrag.active,
              builder: (context, dragging, _) => dragging == null
                  ? const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          AppSpacing.s4,
                          AppSpacing.s4,
                          AppSpacing.s8 + AppSpacing.s4,
                        ),
                        child: TipBubble(id: savedDragTip, text: DiscoverStrings.savedDragTipText),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

String _groupLabel(SavedGroup group) => switch (group) {
  SavedGroup.today => DiscoverStrings.savedGroupToday,
  SavedGroup.yesterday => DiscoverStrings.savedGroupYesterday,
  SavedGroup.thisWeek => DiscoverStrings.savedGroupThisWeek,
  SavedGroup.earlier => DiscoverStrings.savedGroupEarlier,
};

class _DraggableEntry extends StatelessWidget {
  const _DraggableEntry({required this.entry, required this.isHighlight, required this.onUnsave});

  final SavedEntry entry;
  final bool isHighlight;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final card = switch (entry) {
      SavedRecipeEntry() => _RecipeCard(
        entry: entry,
        isHighlight: isHighlight,
        onTap: () => context.push(recipeLocation(entry.recipe.id)),
      ),
      SavedMealEntry() => _MealCard(
        entry: entry,
        isHighlight: isHighlight,
        onTap: () => context.push(savedMealLocation(entry.meal.key)),
      ),
    };
    // Thẻ đang kéo nằm trong overlay, không có bề ngang: giữ đúng bề ngang của danh sách.
    return LayoutBuilder(
      builder: (context, constraints) => HoldDraggable<SavedEntry>(
        data: entry,
        liftedRadius: AppRadius.mdAll,
        semanticsActionLabel: DiscoverStrings.savedUnsaveAction,
        onSemanticsAction: onUnsave,
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.delete): onUnsave},
          child: SizedBox(width: constraints.maxWidth, child: card),
        ),
      ),
    );
  }
}

/// Khung thẻ hàng ngang như thẻ Lịch sử: ảnh 120 bên trái, chữ bên phải; [isHighlight] tô chili và
/// gắn ribbon "Mới thêm".
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.image,
    required this.children,
    required this.isHighlight,
    required this.onTap,
  });

  final Widget image;
  final List<Widget> children;
  final bool isHighlight;
  final VoidCallback onTap;

  static const imageSize = 120.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = Material(
      color: isHighlight ? colors.chiliSoft : colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: isHighlight ? colors.chili : colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.s3,
            children: [
              image,
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ],
          ),
        ),
      ),
    );
    if (!isHighlight) return card;
    return ClipRect(
      child: Banner(
        message: DiscoverStrings.savedJustAdded,
        location: BannerLocation.topEnd,
        color: colors.chili,
        textStyle: AppTextStyles.caption.copyWith(
          color: colors.surfaceRaised,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        child: card,
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.entry, required this.isHighlight, required this.onTap});

  final SavedRecipeEntry entry;
  final bool isHighlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = entry.recipe;
    final availability = entry.availability;
    return _EntryCard(
      isHighlight: isHighlight,
      onTap: onTap,
      image: SizedBox.square(
        dimension: _EntryCard.imageSize,
        child: ClipRRect(
          borderRadius: AppRadius.smAll,
          child: RecipeCover(imageAsset: recipe.imageAsset, aspectRatio: 1),
        ),
      ),
      children: [
        Text(
          recipe.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: colors.ink),
        ),
        Text(
          DiscoverStrings.recipeMeta(
            recipe.minutes,
            recipe.servings,
            recipe.tools.firstOrNull?.shortLabel,
          ),
          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
        ),
        if (availability != null) ...[
          const SizedBox(height: AppSpacing.s2),
          AvailabilityBadge(missing: availability.missing),
        ],
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.entry, required this.isHighlight, required this.onTap});

  final SavedMealEntry entry;
  final bool isHighlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _EntryCard(
      isHighlight: isHighlight,
      onTap: onTap,
      image: MealMosaic(
        size: _EntryCard.imageSize,
        radius: AppRadius.smAll,
        dishes: [for (final r in entry.recipes) MosaicDish(r.name, r.imageAsset)],
      ),
      children: [
        Text(
          entry.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: colors.ink),
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
      ],
    );
  }
}

/// Tag tiêu chí của bữa (nền `chiliSoft`), dùng ở thẻ bữa và Chi tiết bữa.
class SavedTagChip extends StatelessWidget {
  const SavedTagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 2),
      decoration: BoxDecoration(color: colors.chiliSoft, borderRadius: AppRadius.pillAll),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: colors.chiliDeep, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Thùng rác trồi lên khi đang kéo một thẻ.
class _TrashOverlay extends ConsumerWidget {
  const _TrashOverlay({required this.vm});

  final SavedViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<Object?>(
      valueListenable: AppDrag.active,
      builder: (context, dragging, _) {
        final isDragging = dragging is SavedEntry;
        // AnimatedSlide dịch hình nhưng giữ vùng bấm cũ, nên chặn bấm khi không kéo.
        return IgnorePointer(
          ignoring: !isDragging,
          child: AnimatedSlide(
            offset: isDragging ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DragTarget<SavedEntry>(
                onAcceptWithDetails: (details) async {
                  HapticFeedback.selectionClick();
                  await ref.read(tipsSeenProvider.notifier).markSeen(savedDragTip);
                  if (context.mounted) await _unsave(context, vm, details.data);
                },
                builder: (context, candidates, _) => _TrashBar(danger: candidates.isNotEmpty),
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
            child: Icon(AppIcons.trash, size: 28, color: danger ? Colors.white : colors.ink),
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
