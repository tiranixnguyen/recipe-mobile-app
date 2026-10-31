import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
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
                                recipes: state.recipes,
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
    required this.recipes,
    required this.isHighlight,
    required this.onTap,
  });

  final CookHistoryEntry entry;
  final String Function(String) nameOf;
  final Map<String, Recipe> recipes;
  final bool isHighlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dishes = entry.dishes;
    final title = '${entry.meal.label} (${_dayDate(entry.cookedAt)})';
    final meta =
        '${dishes.length} món · ${entry.servings} người'
        '${entry.minutes > 0 ? ' · ~${entry.minutes} phút' : ''}';

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
              MealMosaic(
                size: 120,
                radius: AppRadius.smAll,
                dishes: [
                  for (final d in dishes)
                    MosaicDish(nameOf(d.recipeId), recipes[d.recipeId]?.imageAsset),
                ],
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
                      ],
                    ),
                    Text(meta, style: AppTextStyles.caption.copyWith(color: colors.inkMuted)),

                    // Dùng vòng lặp for duyệt qua dữ liệu đã được xử lý
                    for (final item in _getDisplayDishes(dishes))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s1),
                        child: Row(
                          spacing: AppSpacing.s1,
                          children: [
                            if (item.dish.rating != null)
                              Icon(
                                ratingIcon(item.dish.rating!),
                                size: 16,
                                color: switch (item.dish.rating!) {
                                  CookRating.good => colors.herb,
                                  CookRating.ok => colors.inkMuted,
                                  CookRating.bad => colors.danger,
                                },
                              ),
                            Flexible(
                              child: Text(
                                item.dish.rating == null
                                    // Tên món + (nếu có extraCount thì thêm ", +X")
                                    ? '${nameOf(item.dish.recipeId)}: ${CookStrings.historyDishNotRated}${item.extraCount > 0 ? ', +${item.extraCount}' : ''}'
                                    : '${nameOf(item.dish.recipeId)}${item.extraCount > 0 ? ', +${item.extraCount}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (entry.mealNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s1),
                        child: Text(
                          '${dishes.length == 1 ? 'Ghi chú' : 'Nhận xét chung'}: ${entry.mealNote}',
                          maxLines: switch (dishes.length) {
                            <= 1 => 3, // 1 món (hoặc 0) -> max 3 dòng
                            2 => 2, // 2 món -> max 2 dòng
                            _ => 1, // 3 món trở lên -> max 1 dòng
                          },
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

    if (isHighlight) {
      return ClipRect(
        child: Banner(
          message: CookStrings.historyJustCooked,
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
    return card;
  }

  Iterable<({CookedDish dish, int extraCount})> _getDisplayDishes(List<CookedDish> dishes) {
    // 1. Dưới 4 món: Trả về từng món, extraCount = 0
    if (dishes.length < 4) {
      return dishes.map((d) => (dish: d, extraCount: 0));
    }

    // 2. Từ 4 món trở lên: Gom nhóm theo rating
    final grouped = <CookRating?, List<CookedDish>>{};
    for (final d in dishes) {
      grouped.putIfAbsent(d.rating, () => []).add(d);
    }

    // Trả về món đầu tiên của nhóm và số lượng phần bù
    return grouped.values.map((list) => (dish: list.first, extraCount: list.length - 1));
  }
}

/// "Chủ nhật 26/10" — dùng cho tiêu đề card Lịch sử nấu.
String _dayDate(DateTime dt) {
  const weekdays = {
    DateTime.monday: 'Thứ hai',
    DateTime.tuesday: 'Thứ ba',
    DateTime.wednesday: 'Thứ tư',
    DateTime.thursday: 'Thứ năm',
    DateTime.friday: 'Thứ sáu',
    DateTime.saturday: 'Thứ bảy',
    DateTime.sunday: 'Chủ nhật',
  };
  return '${weekdays[dt.weekday]} ${dt.day}/${dt.month}';
}
