import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
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
                        '${value.length} món phù hợp',
                        style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      );
                    }
                    final recipe = value[index - 1];
                    return Consumer(
                      builder: (context, ref, _) {
                        final availability = ref.watch(availabilityProvider(recipe));
                        return RecipeRow(
                          title: recipe.name,
                          imageAsset: recipe.imageAsset,
                          thumbSize: 88,
                          meta: availability == null
                              ? '${recipe.minutes} phút · ${recipe.servings} người'
                              : '${recipe.minutes} phút · ${availability.missing.isEmpty ? 'Đủ đồ' : 'Thiếu ${availability.missing.length} thứ'}',
                          onTap: () => context.push(recipeLocation(recipe.id)),
                        );
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
