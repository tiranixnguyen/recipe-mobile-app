import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/history/history_view_model.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';

/// Màn lịch sử nấu — tab thứ 4 (index 3).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.highlightId});

  final String? highlightId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyViewModelProvider(highlightId));
    final viewModel = ref.read(historyViewModelProvider(highlightId).notifier);
    final now = DateTime.now();

    // Hiện snackbar "Đã lưu vào lịch sử nấu" một lần khi có highlight.
    if (state.highlightId != null && !state.snackShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          AppSnackbar.show(context, CookStrings.historySaved);
          viewModel.markSnackShown();
        }
      });
    }

    final grouped = state.grouped(now);
    final isEmpty = state.filtered.isEmpty;
    final thisMonth = state.thisMonthCount(now);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text(CookStrings.historyTitle),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  0,
                  AppSpacing.s4,
                  AppSpacing.s3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                ),
              ),
            ),
          ),
          if (thisMonth > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  0,
                  AppSpacing.s4,
                  AppSpacing.s2,
                ),
                child: Text(
                  CookStrings.historyMonthCount(thisMonth),
                  style: AppTextStyles.caption.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
              ),
            ),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: AppIcons.bowl,
                  title: CookStrings.historyEmptyTitle,
                  message: CookStrings.historyEmptyBody,
                  actionLabel: CookStrings.historyEmptyAction,
                  onAction: () => context.go(discoverLocation),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: grouped.fold<int>(0, (sum, g) => sum + 1 + g.$2.length),
              itemBuilder: (context, index) {
                int offset = 0;
                for (final (label, entries) in grouped) {
                  if (index == offset) {
                    return _GroupHeader(label: label);
                  }
                  offset++;
                  final entryIdx = index - offset;
                  if (entryIdx >= 0 && entryIdx < entries.length) {
                    return _HistoryEntryTile(
                      entry: entries[entryIdx],
                      isHighlight: entries[entryIdx].id == state.highlightId,
                      onTap: () => context.push('/history/${entries[entryIdx].id}'),
                    );
                  }
                  offset += entries.length;
                }
                return null;
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.s6)),
        ],
      ),
    );
  }
}

String _filterLabel(HistoryFilter filter) => switch (filter) {
  HistoryFilter.all => CookStrings.historyFilterAll,
  HistoryFilter.good => CookStrings.historyFilterGood,
  HistoryFilter.note => CookStrings.historyFilterNote,
};

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s1,
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: context.colors.inkMuted),
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({
    required this.entry,
    required this.isHighlight,
    required this.onTap,
  });

  final CookHistoryEntry entry;
  final bool isHighlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dishes = entry.dishes;
    final names = dishes.take(3).map((d) => d.recipeId).toList();
    final extra = dishes.length > 3 ? dishes.length - 3 : 0;
    final nameStr = [
      ...names,
      if (extra > 0) '+$extra',
    ].join(', ');

    final ratingIcons = [
      for (final d in dishes.take(3))
        if (d.rating case final r?) _ratingIcon(r),
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: AppSpacing.s2,
                    children: [
                      if (isHighlight)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.chiliSoft,
                            borderRadius: AppRadius.smAll,
                          ),
                          child: Text(
                            CookStrings.historyJustCooked,
                            style: AppTextStyles.caption.copyWith(color: colors.chiliDeep),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          nameStr,
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
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(entry.cookedAt),
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
            if (ratingIcons.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.s2),
              Row(
                spacing: 2,
                children: [
                  for (final icon in ratingIcons) Icon(icon, size: 18, color: colors.inkMuted),
                ],
              ),
            ],
            const SizedBox(width: AppSpacing.s1),
            Icon(AppIcons.chevron, size: 20, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

IconData _ratingIcon(CookRating r) => switch (r) {
  CookRating.good => AppIcons.smile,
  CookRating.ok => AppIcons.meh,
  CookRating.bad => AppIcons.frown,
};

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inHours < 1) return 'Vừa xong';
  if (diff.inDays == 0) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.day}/${dt.month}/${dt.year}';
}
