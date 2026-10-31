import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/domain/history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history/history_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_done_widgets.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';

/// Màn Lịch sử nấu — tab thứ 4 (index 3), mở sẵn với `highlightId` khi vừa nấu xong.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.highlightId});

  final String? highlightId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyViewModelProvider(highlightId));
    final viewModel = ref.read(historyViewModelProvider(highlightId).notifier);
    final colors = context.colors;
    final now = viewModel.now();

    if (state.highlightId != null && !viewModel.snackShown) {
      viewModel.markSnackShown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) AppSnackbar.show(context, CookStrings.historySaved);
      });
    }

    final groups = state.groups(now);
    final monthCount = state.monthCount(now);

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                  Text(
                    CookStrings.historyTitle,
                    style: AppTextStyles.title.copyWith(color: colors.ink),
                  ),
                  Text(
                    state.entries.isEmpty
                        ? CookStrings.historyEmptyHeadMeta
                        : CookStrings.historyMonthCount(monthCount),
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                  if (state.entries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s3),
                    SearchField(
                      placeholder: CookStrings.historySearch,
                      onChanged: viewModel.search,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: AppSpacing.s2,
                        children: [
                          for (final filter in HistoryFilter.values)
                            AppChip(
                              label: _filterLabel(filter),
                              selected: state.filter == filter,
                              onTap: () => viewModel.setFilter(filter),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state.entries.isEmpty
                  ? _EmptyHistory(onSuggest: () => context.go(discoverLocation))
                  : groups.isEmpty
                  ? Center(
                      child: Text(
                        state.query.trim().isNotEmpty
                            ? CookStrings.historyNoMatch(state.query.trim())
                            : CookStrings.historyNoMatchFilter,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: colors.inkMuted),
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
                              child: _HistoryEntryCard(
                                entry: entry,
                                nameOf: state.nameOf,
                                isHighlight: entry.id == state.highlightId,
                                onTap: () => context.push(historyEntryLocation(entry.id)),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _filterLabel(HistoryFilter filter) => switch (filter) {
  HistoryFilter.all => CookStrings.historyFilterAll,
  HistoryFilter.good => CookStrings.historyFilterGood,
  HistoryFilter.note => CookStrings.historyFilterNote,
};

String _groupLabel(HistoryGroup group) => switch (group) {
  HistoryGroup.today => CookStrings.historyGroupToday,
  HistoryGroup.yesterday => CookStrings.historyGroupYesterday,
  HistoryGroup.thisWeek => CookStrings.historyGroupThisWeek,
  HistoryGroup.earlier => CookStrings.historyGroupEarlier,
};

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onSuggest});

  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CookStrings.historyEmptyTitle,
              style: AppTextStyles.title.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              CookStrings.historyEmptyBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(label: CookStrings.historyEmptyAction, onPressed: onSuggest),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.nameOf,
    required this.isHighlight,
    required this.onTap,
  });

  final CookHistoryEntry entry;
  final String Function(String) nameOf;
  final bool isHighlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dishes = entry.dishes;
    final one = dishes.length == 1;
    final title = one
        ? nameOf(dishes.first.recipeId)
        : '${entry.meal.label} · ${_shortDate(entry.cookedAt)}';
    final meta = one
        ? '${entry.meal.label} · ${_shortDate(entry.cookedAt)} · ${dishes.first.servings} người'
        : '${dishes.length} món · ${entry.servings} người'
              '${entry.minutes > 0 ? ' · ~${entry.minutes} phút' : ''}';

    return Material(
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
              MealMosaic(
                size: 72,
                radius: AppRadius.smAll,
                dishes: [for (final d in dishes) MosaicDish(nameOf(d.recipeId))],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: AppSpacing.s2,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        if (isHighlight)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.chili,
                              borderRadius: AppRadius.pillAll,
                            ),
                            child: Text(
                              CookStrings.historyJustCooked,
                              style: AppTextStyles.caption.copyWith(color: colors.surfaceRaised),
                            ),
                          ),
                      ],
                    ),
                    Text(meta, style: AppTextStyles.caption.copyWith(color: colors.inkMuted)),
                    if (!one)
                      for (final dish in dishes.take(3))
                        Row(
                          spacing: AppSpacing.s1,
                          children: [
                            if (dish.rating case final r?)
                              Icon(ratingIcon(r), size: 16, color: colors.inkMuted),
                            Flexible(
                              child: Text(
                                nameOf(dish.recipeId),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                              ),
                            ),
                          ],
                        ),
                    if (!one && dishes.length > 3)
                      Text(
                        '+${dishes.length - 3} món',
                        style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      ),
                    if (entry.mealNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          entry.mealNote,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.inkMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
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

String _shortDate(DateTime dt) => '${dt.day}/${dt.month}';
