import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_logo.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_card.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_row.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Khám phá (prototype `Main`): lối vào Hôm nay ăn gì, tìm kiếm, món nấu được với đồ đang có và món
/// nhanh.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  /// Chip nhanh mở Tìm kiếm có sẵn bộ lọc.
  static final _quickFilters = [
    (DiscoverStrings.quickUnder15, searchLocation(maxMinutes: 15)),
    (DiscoverStrings.quickRiceCooker, searchLocation(tool: Tool.rice)),
    (DiscoverStrings.quickVeg, searchLocation(diet: Diet.veg)),
    (DiscoverStrings.quickDinner, searchLocation(meal: Meal.dinner)),
  ];

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateVisibility();
  }

  void _updateVisibility() {
    // indexedStack giữ tab còn sống; TickerMode tắt cho nhánh đang ẩn.
    final routeVisible =
        (ModalRoute.of(context)?.isCurrent ?? false) && TickerMode.valuesOf(context).enabled;
    if (routeVisible && !_visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            (ModalRoute.of(context)?.isCurrent ?? false) &&
            TickerMode.valuesOf(context).enabled) {
          ref.read(discoverViewModelProvider.notifier).recordView();
        }
      });
    } else if (!routeVisible && _visible) {
      ref.read(discoverViewModelProvider.notifier).endView();
    }
    _visible = routeVisible;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(discoverViewModelProvider);
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
                  const Padding(padding: side, child: _Hero()),
                  gap,
                  Padding(
                    padding: side,
                    child: SearchField(
                      readOnly: true,
                      placeholder: DiscoverStrings.searchPlaceholder,
                      onTap: () => context.push(searchLocation()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: side,
                    child: Row(
                      spacing: AppSpacing.s2,
                      children: [
                        for (final (label, location) in DiscoverScreen._quickFilters)
                          AppChip(
                            label: label,
                            selected: false,
                            onTap: () => context.push(location),
                          ),
                      ],
                    ),
                  ),
                  gap,
                  ...switch (state) {
                    AsyncData(:final value) => [
                      _CookableSection(cookable: value.cookable),
                      if (value.quick.isNotEmpty) ...[gap, _QuickSection(quick: value.quick)],
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

/// Khối "Hôm nay ăn gì?" nền `chiliSoft`.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.chiliSoft, borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DiscoverStrings.heroTitle,
              style: AppTextStyles.display.copyWith(color: colors.chiliDeep),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(DiscoverStrings.heroBody, style: AppTextStyles.body.copyWith(color: colors.ink)),
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              label: DiscoverStrings.heroAction,
              onPressed: () => context.push(todayLocation),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: AppTextStyles.subtitle.copyWith(color: context.colors.ink),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// "Nấu được với đồ bạn có": thẻ ngang rộng 200 kèm `AvailabilityBadge`.
class _CookableSection extends StatelessWidget {
  const _CookableSection({required this.cookable});

  final List<NearMatch> cookable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          DiscoverStrings.cookable,
          trailing: TextButton(
            onPressed: () => context.go(pantryLocation),
            style: TextButton.styleFrom(
              foregroundColor: colors.chiliDeep,
              textStyle: AppTextStyles.label,
            ),
            child: const Text(DiscoverStrings.openPantry),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        if (cookable.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Text(
              DiscoverStrings.cookableEmpty,
              style: AppTextStyles.body.copyWith(color: colors.inkMuted),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s3,
              children: [
                for (final (:recipe, :availability) in cookable)
                  SizedBox(
                    width: 200,
                    child: RecipeCard(
                      title: recipe.name,
                      minutes: recipe.minutes,
                      tool: recipe.tools.firstOrNull?.shortLabel,
                      imageAsset: recipe.imageAsset,
                      badge: AvailabilityBadge(missing: availability.missing),
                      onTap: () => context.push(recipeLocation(recipe.id)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Nhanh sau giờ học": hàng món nấu nhanh.
class _QuickSection extends StatelessWidget {
  const _QuickSection({required this.quick});

  final List<Recipe> quick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(DiscoverStrings.quick),
        const SizedBox(height: AppSpacing.s3),
        for (final recipe in quick)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s2),
            child: RecipeRow(
              title: recipe.name,
              meta: recipeMeta(recipe, servings: true),
              imageAsset: recipe.imageAsset,
              onTap: () => context.push(recipeLocation(recipe.id)),
            ),
          ),
      ],
    );
  }
}
