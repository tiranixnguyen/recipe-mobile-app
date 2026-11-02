import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_logo.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/domain/banner_art.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_view_model.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/suggestion_banner.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Khám phá v2 (prototype `Main.dc.html`): nơi trả lời "bữa tới ăn gì":
/// - Banner gợi ý theo ngữ cảnh (carousel)
/// - "Sắp tới bữa … rồi" từ thực đơn
/// - "Nấu được ngay" từ tủ đồ
/// - Lối vào "Đi chợ"
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  static final _quickFilters = [
    (DiscoverStrings.quickUnder15, searchLocation(maxMinutes: 15)),
    (DiscoverStrings.quickRiceCooker, searchLocation(tool: Tool.rice)),
    (DiscoverStrings.quickVeg, searchLocation(diet: Diet.veg)),
    (DiscoverStrings.quickDinner, searchLocation(meal: Meal.dinner)),
  ];

  static String _weekdayName(DateTime date) => switch (date.weekday) {
    DateTime.monday => 'thứ Hai',
    DateTime.tuesday => 'thứ Ba',
    DateTime.wednesday => 'thứ Tư',
    DateTime.thursday => 'thứ Năm',
    DateTime.friday => 'thứ Sáu',
    DateTime.saturday => 'thứ Bảy',
    _ => 'Chủ Nhật',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(discoverViewModelProvider);
    final viewModel = ref.read(discoverViewModelProvider.notifier);
    const gap = SizedBox(height: AppSpacing.s6);
    const side = EdgeInsets.symmetric(horizontal: AppSpacing.s4);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                children: [
                  const ResumeCookingBanner(),
                  const GettingStartedCard(),
                  Padding(
                    padding: side,
                    child: SearchField(
                      readOnly: true,
                      placeholder: DiscoverStrings.searchPlaceholder,
                      onTap: () => context.push(searchLocation()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Padding(
                    padding: side,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: AppSpacing.s2,
                        children: [
                          for (final (label, location) in _quickFilters)
                            AppChip(
                              label: label,
                              selected: false,
                              onTap: () => context.push(location),
                            ),
                        ],
                      ),
                    ),
                  ),
                  gap,
                  ...switch (state) {
                    AsyncData(:final value) => [
                      _BannerCarousel(
                        state: value,
                        onTapCard: (card) {
                          viewModel.trackBannerTap(card);
                          context.push(todayLocation);
                        },
                        onTapSettings: () {
                          viewModel.trackBannerTap('weather');
                          context.push(settingsLocation);
                        },
                        onTapPantry: () {
                          viewModel.trackBannerTap('fridge');
                          context.go(pantryLocation);
                        },
                      ),
                      gap,
                      _UpcomingSection(state: value),
                      gap,
                      _ReadyToCookSection(state: value),
                      gap,
                      _ShoppingSection(state: value),
                    ],
                    AsyncError() => [
                      Padding(
                        padding: side,
                        child: Text(
                          DiscoverStrings.loadError,
                          style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                        ),
                      ),
                    ],
                    _ => [const Center(child: CircularProgressIndicator())],
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s2,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          const AppLogo(),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                DiscoverStrings.appName,
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push(settingsLocation),
            tooltip: DiscoverStrings.settings,
            icon: Icon(AppIcons.sliders, color: colors.ink),
            style: IconButton.styleFrom(minimumSize: const Size.square(48)),
          ),
        ],
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.state,
    required this.onTapCard,
    required this.onTapSettings,
    required this.onTapPantry,
  });

  final DiscoverState state;
  final ValueChanged<String> onTapCard;
  final VoidCallback onTapSettings;
  final VoidCallback onTapPantry;

  @override
  Widget build(BuildContext context) {
    final weekday = DiscoverScreen._weekdayName(state.now);
    final (timeTitle, timeDesc, timeTags, timeCtx) = switch (state.upcomingMeal) {
      Meal.breakfast => (
        'Sáng nay vội?',
        'Siêu tốc dưới 15 phút, ít rửa bát.',
        ['Siêu tốc', '1 món gọn lẹ'],
        'Sáng $weekday',
      ),
      Meal.lunch => (
        'Nghỉ trưa ngắn?',
        'Nhanh gọn dưới 30 phút, kịp ăn rồi nghỉ.',
        ['Nhanh gọn'],
        'Nghỉ trưa $weekday',
      ),
      Meal.dinner => (
        'Tối nay thong thả',
        'Mâm cơm 3 món, nấu cùng bạn cùng phòng.',
        ['Mâm cơm', 'Thong thả'],
        'Tối $weekday',
      ),
    };

    final timeCard = switch (state.upcomingMeal) {
      Meal.breakfast => BannerCard.breakfast,
      Meal.lunch => BannerCard.lunch,
      Meal.dinner => BannerCard.dinner,
    };

    final pantryCount = state.readyDishes.length;
    final pantryNames = state.pantryIngredientNames;
    final fridgeTitle = pantryNames.isNotEmpty
        ? 'Tủ còn ${pantryNames.take(3).join(', ')}'
        : 'Dọn tủ lạnh';
    final fridgeDesc = '$pantryCount món nấu được ngay, không phải đi chợ.';

    final items = [
      SuggestionBannerItem(
        title: timeTitle,
        description: timeDesc,
        contextText: timeCtx,
        icon: AppIcons.clock,
        tags: timeTags,
        art: state.bannerArt[timeCard],
        onTap: () => onTapCard('time'),
      ),
      SuggestionBannerItem(
        title: fridgeTitle,
        description: fridgeDesc,
        contextText: 'Dọn tủ lạnh',
        icon: AppIcons.fridge,
        tags: const ['Dọn tủ lạnh'],
        art: state.bannerArt[BannerCard.fridge],
        onTap: onTapPantry,
      ),
      SuggestionBannerItem(
        title: 'Cuối tháng rồi',
        description: 'Hệ tiết kiệm: tận dụng đồ sẵn có, ít phải mua thêm.',
        contextText: 'Cuối tháng',
        icon: Symbols.eco_rounded,
        tags: const ['Tiết kiệm'],
        art: state.bannerArt[BannerCard.endOfMonth],
        onTap: () => onTapCard('cheap'),
      ),
      SuggestionBannerItem(
        title: 'Trời nóng hay mưa?',
        description: 'Bật để app gợi ý món hợp thời tiết. Cần vị trí gần đúng và mạng.',
        contextText: 'Gợi ý theo thời tiết',
        icon: AppIcons.info,
        tags: const ['Tuỳ chọn'],
        ctaLabel: 'Bật',
        hasTrailingArrow: false,
        art: state.bannerArt[BannerCard.weatherOptIn],
        onTap: onTapSettings,
      ),
    ];

    return SuggestionBanner(
      items: items,
      onPreferencesTap: () => context.push(todayPrefsLocation),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.state});

  final DiscoverState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mealLabel = state.upcomingMeal.label.toLowerCase();
    final hasDishes = state.upcomingDishes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    DiscoverStrings.upcomingTitle(mealLabel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                  ),
                ),
              ),
              if (hasDishes) ...[
                const SizedBox(width: AppSpacing.s2),
                _CookMealPill(
                  isMultiple: state.upcomingDishes.length > 1,
                  onTap: () {
                    if (state.upcomingDishes.length > 1) {
                      context.push(mealCookLocation(state.now, state.upcomingMeal));
                    } else {
                      context.push(cookPrepLocation(state.upcomingDishes.first.id));
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (hasDishes) ...[
            Semantics(
              button: true,
              label: DiscoverStrings.openUpcomingPlan(mealLabel),
              child: InkWell(
                onTap: () => context.go(planLocation()),
                borderRadius: AppRadius.mdAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.s1,
                  children: [
                    for (final dish in state.upcomingDishes) _DishTile(recipe: dish),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              DiscoverStrings.upcomingEmpty(mealLabel),
              style: AppTextStyles.meta.copyWith(
                fontWeight: FontWeight.w400,
                color: colors.inkMuted,
              ),
            ),
            const SizedBox(height: 10),
            for (final idea in state.upcomingIdeas) ...[
              _IdeaTile(
                recipe: idea,
                mealLabel: mealLabel,
                onTap: () => context.push(recipeLocation(idea.id)),
                onAdd: () => showAddToPlanSheet(context, idea),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
          ],
        ],
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s2),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              width: 56,
              height: 56,
              child: RecipeCover(imageAsset: recipe.imageAsset, aspectRatio: 1),
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
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recipeMeta(recipe),
                  style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({
    required this.recipe,
    required this.mealLabel,
    required this.onTap,
    required this.onAdd,
  });

  final Recipe recipe;
  final String mealLabel;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s2),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: RecipeCover(imageAsset: recipe.imageAsset, aspectRatio: 1),
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
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${recipeMeta(recipe)} · Đủ đồ',
                          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            button: true,
            label: DiscoverStrings.addDishAria(recipe.name, mealLabel),
            child: InkWell(
              onTap: onAdd,
              borderRadius: AppRadius.pillAll,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  border: Border.all(color: colors.outline),
                  borderRadius: AppRadius.pillAll,
                ),
                alignment: Alignment.center,
                child: Text(
                  DiscoverStrings.addDish,
                  style: AppTextStyles.meta.copyWith(color: colors.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CookMealPill extends StatelessWidget {
  const _CookMealPill({required this.isMultiple, required this.onTap});

  final bool isMultiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = isMultiple ? DiscoverStrings.cookMeal : DiscoverStrings.cookDish;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.chiliSoft,
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.skillet_rounded, size: 14, color: colors.chiliDeep),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: colors.chiliDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyToCookSection extends StatelessWidget {
  const _ReadyToCookSection({required this.state});

  final DiscoverState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ready = state.readyDishes;
    final isEmpty = ready.isEmpty;
    final hasPantry = state.pantryIngredientNames.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    DiscoverStrings.readyToCook,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                  ),
                ),
              ),
              if (!isEmpty) ...[
                const SizedBox(width: AppSpacing.s2),
                InkWell(
                  onTap: () => context.go(pantryLocation),
                  borderRadius: AppRadius.smAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      DiscoverStrings.openPantry,
                      style: AppTextStyles.meta.copyWith(color: colors.chiliDeep),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: _EntryCard(
              icon: AppIcons.fridge,
              title: hasPantry
                  ? DiscoverStrings.readyEmptyNoMatchTitle
                  : DiscoverStrings.readyEmptyPantryTitle,
              subtitle: hasPantry
                  ? DiscoverStrings.readyEmptyNoMatchBody
                  : DiscoverStrings.readyEmptyPantryBody,
              onTap: () => context.go(pantryLocation),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 12,
                children: [
                  for (final dish in ready)
                    _ReadyCard(
                      recipe: dish,
                      onTap: () => context.push(recipeLocation(dish.id)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: recipe.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            border: Border.all(color: colors.line),
            borderRadius: AppRadius.mdAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RecipeCover(imageAsset: recipe.imageAsset),
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: AvailabilityBadge(missing: []),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipeMeta(recipe),
                      style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
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

class _ShoppingSection extends StatelessWidget {
  const _ShoppingSection({required this.state});

  final DiscoverState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasItems = state.shoppingCount > 0;
    final title = hasItems
        ? DiscoverStrings.shoppingNeedBuy(state.shoppingCount)
        : DiscoverStrings.shoppingEmpty;
    final subtitle = hasItems
        ? state.shoppingPreview.take(3).join(', ')
        : DiscoverStrings.shoppingEmptySub;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              DiscoverStrings.shoppingTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(height: 12),
          _EntryCard(
            icon: AppIcons.basket,
            title: title,
            subtitle: subtitle,
            onTap: () => context.push(shoppingLocation),
          ),
        ],
      ),
    );
  }
}

/// Thẻ lối vào dạng icon tròn + tiêu đề + dòng phụ + chevron, cả thẻ bấm được. Dùng cho Đi chợ và
/// trạng thái trống của Nấu được ngay.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.line),
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.chiliSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: colors.chili),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.meta.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevron, size: 20, color: colors.inkMuted),
          ],
        ),
      ),
    );
  }
}
