import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/search/search_view_model.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.query, this.maxMinutes, this.tool, this.diet, this.meal});

  final String? query;
  final int? maxMinutes;
  final Tool? tool;
  final Diet? diet;
  final Meal? meal;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query ?? '');
    // Khởi tạo provider sau khi phần tử đã gắn vào cây.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(searchViewModelProvider.notifier)
          .initialize(
            query: widget.query,
            maxMinutes: widget.maxMinutes,
            tool: widget.tool,
            diet: widget.diet,
            meal: widget.meal,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(searchViewModelProvider);
    final results = ref.watch(searchResultsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s1,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s2,
              ),
              child: Row(
                children: [
                  BackButton(color: colors.ink),
                  Expanded(
                    child: SearchField(
                      controller: _controller,
                      autofocus: widget.query == null,
                      placeholder: DiscoverStrings.searchPlaceholder,
                      onChanged: ref.read(searchViewModelProvider.notifier).setQuery,
                      onSubmitted: (_) => ref.read(searchViewModelProvider.notifier).submit(),
                    ),
                  ),
                  if (state.query.isNotEmpty)
                    IconButton(
                      tooltip: 'Xoá từ khoá',
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchViewModelProvider.notifier).setQuery('');
                      },
                      icon: Icon(AppIcons.close, color: colors.inkMuted),
                    ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                spacing: AppSpacing.s2,
                children: [
                  AppChip(
                    label: DiscoverStrings.quickUnder15,
                    selected: state.maxMinutes == 15,
                    onTap: () => ref.read(searchViewModelProvider.notifier).toggleMinutes(15),
                  ),
                  AppChip(
                    label: DiscoverStrings.quickRiceCooker,
                    selected: state.tool == Tool.rice,
                    onTap: () => ref.read(searchViewModelProvider.notifier).toggleTool(Tool.rice),
                  ),
                  AppChip(
                    label: DiscoverStrings.quickDinner,
                    selected: state.meal == Meal.dinner,
                    onTap: () => ref.read(searchViewModelProvider.notifier).toggleMeal(Meal.dinner),
                  ),
                  AppChip(
                    label: DiscoverStrings.quickVeg,
                    selected: state.diet == Diet.veg,
                    onTap: () => ref.read(searchViewModelProvider.notifier).toggleDiet(Diet.veg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Expanded(
              child: switch (results) {
                AsyncData(:final value) => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                    vertical: AppSpacing.s2,
                  ),
                  itemCount: value.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        state.summary(value.length),
                        style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      );
                    }
                    final recipe = value[index - 1];
                    return Consumer(
                      builder: (context, ref, _) {
                        final availability = ref.watch(availabilityProvider(recipe));
                        return _SearchResult(recipe: recipe, availability: availability?.missing);
                      },
                    );
                  },
                ),
                AsyncError() => Center(
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

class _SearchResult extends StatelessWidget {
  const _SearchResult({required this.recipe, required this.availability});

  final Recipe recipe;
  final List<String>? availability;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () => context.push(recipeLocation(recipe.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s2),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: RecipeCover(imageAsset: recipe.imageAsset),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                    ),
                    Text(
                      '${recipe.minutes} phút · ${recipe.servings} người',
                      style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                    ),
                    if (availability != null) AvailabilityBadge(missing: availability!),
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
