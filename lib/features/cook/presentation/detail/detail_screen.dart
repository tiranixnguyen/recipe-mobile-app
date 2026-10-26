import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/features/cook/domain/recipe_detail.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Chi tiết món (prototype `Detail`): ảnh, badge đủ/thiếu đồ, nguyên liệu so với Tủ đồ, các bước;
/// dưới cùng "Thêm vào thực đơn" và "Bắt đầu nấu".
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(detailViewModelProvider(recipeId))) {
      AsyncData(:final value) => Scaffold(body: _Detail(state: value)),
      // Tạm: SET-18 thay bằng màn lỗi `notfound`.
      AsyncError(error: RecipeNotFound()) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            title: CookStrings.notFoundTitle,
            message: CookStrings.notFoundBody,
            actionLabel: CookStrings.notFoundAction,
            onAction: () => context.go(discoverLocation),
          ),
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            CookStrings.loadError,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.state});

  final DetailState state;

  @override
  Widget build(BuildContext context) {
    final recipe = state.recipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Cover(recipe: recipe),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.s5,
                  children: [
                    _Summary(state: state),
                    _Ingredients(state: state),
                    _Steps(steps: state.steps),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Footer(recipe: recipe),
      ],
    );
  }
}

/// Ảnh cao 240, nút tròn 48 "Quay lại" bên trái và Lưu bên phải.
class _Cover extends StatelessWidget {
  const _Cover({required this.recipe});

  final Recipe recipe;

  static const height = 240.0;
  static const buttonSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: height + MediaQuery.paddingOf(context).top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RecipeCover(imageAsset: recipe.imageAsset),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go(discoverLocation),
                    tooltip: CookStrings.back,
                    icon: const Icon(AppIcons.back),
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(buttonSize),
                      minimumSize: const Size.square(buttonSize),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: colors.surfaceRaised,
                      foregroundColor: colors.ink,
                    ),
                  ),
                  SaveButton(recipeId: recipe.id, size: buttonSize),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge, dòng meta có icon, tên món, mô tả.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final DetailState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = state.recipe;
    final tool = recipe.tools.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s2,
      children: [
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AvailabilityBadge(missing: state.availability.missing),
            _MetaItem(icon: AppIcons.clock, text: '${recipe.minutes} phút'),
            _MetaItem(icon: AppIcons.person, text: '${recipe.servings} người'),
            if (tool != null) _MetaItem(icon: _toolIcon(tool), text: tool.shortLabel),
          ],
        ),
        Semantics(
          header: true,
          child: Text(recipe.name, style: AppTextStyles.display.copyWith(color: colors.ink)),
        ),
        if (recipe.description.isNotEmpty)
          Text(
            recipe.description,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
      ],
    );
  }

  /// Bộ icon của design không có dụng cụ bếp; prototype vẽ riêng, nên lấy gần nhất từ Material
  /// Symbols.
  static IconData _toolIcon(Tool tool) => switch (tool) {
    Tool.rice => Symbols.stockpot_rounded,
    Tool.stove => Symbols.cooking_rounded,
    Tool.micro => Symbols.microwave_rounded,
    Tool.kettle => Symbols.kettle_rounded,
  };
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.s1,
      children: [
        Icon(icon, size: 16, color: colors.inkMuted),
        Text(text, style: AppTextStyles.meta.copyWith(color: colors.inkMuted)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: AppTextStyles.subtitle.copyWith(color: context.colors.ink)),
  );
}

/// Khung `surfaceRaised` viền `line`: mỗi nguyên liệu một dòng kèm trạng thái, gia vị cơ bản gom
/// dòng cuối.
class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.state});

  final DetailState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spices = state.basicSpices;
    final rows = [
      for (final item in state.ingredients)
        _IngredientRow(
          text: '${item.name} · ${item.amountText}',
          status: switch (item.status) {
            IngredientStatus.inPantry => CookStrings.inPantry,
            IngredientStatus.missing => CookStrings.missing,
            IngredientStatus.optional => CookStrings.optional,
          },
          textColor: colors.ink,
          statusColor: switch (item.status) {
            IngredientStatus.inPantry => colors.herbInk,
            IngredientStatus.missing => colors.chiliDeep,
            IngredientStatus.optional => colors.inkMuted,
          },
        ),
      if (spices.isNotEmpty)
        _IngredientRow(
          text: spices.join(', '),
          status: CookStrings.basicSpices,
          textColor: colors.inkMuted,
          statusColor: colors.inkMuted,
          statusWeight: FontWeight.w400,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s2,
      children: [
        const _SectionTitle(CookStrings.ingredients),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            border: Border.all(color: colors.line),
            borderRadius: AppRadius.mdAll,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(
              children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
                  row,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.text,
    required this.status,
    required this.textColor,
    required this.statusColor,
    this.statusWeight = FontWeight.w600,
  });

  final String text;
  final String status;
  final Color textColor;
  final Color statusColor;
  final FontWeight statusWeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s3,
        children: [
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(color: textColor)),
          ),
          Text(
            status,
            style: AppTextStyles.body.copyWith(color: statusColor, fontWeight: statusWeight),
          ),
        ],
      ),
    );
  }
}

/// "Cách làm · n bước": số tròn 24 `chiliSoft`, chữ bước, "· 1 phút" khi có hẹn giờ.
class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<DetailStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s2,
      children: [
        _SectionTitle(CookStrings.steps(steps.length)),
        for (final (i, step) in steps.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.s3,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.chiliSoft, shape: BoxShape.circle),
                child: Text(
                  '${i + 1}',
                  textScaler: TextScaler.noScaling,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.chiliDeep,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: step.text,
                    children: [
                      if (step.timeLabel case final time?)
                        TextSpan(
                          text: ' · $time',
                          style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                        ),
                    ],
                  ),
                  style: AppTextStyles.body.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// "Thêm vào thực đơn" mở sheet của Thực đơn; "Bắt đầu nấu" sang Chuẩn bị nấu.
class _Footer extends StatelessWidget {
  const _Footer({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: Row(
            spacing: AppSpacing.s3,
            children: [
              // 1.2 : 1 như prototype.
              Expanded(
                flex: 6,
                child: AppButton.secondary(
                  label: CookStrings.addToPlan,
                  icon: AppIcons.calendar,
                  block: true,
                  onPressed: () => showAddToPlanSheet(context, recipe),
                ),
              ),
              Expanded(
                flex: 5,
                child: AppButton(
                  label: CookStrings.startCooking,
                  block: true,
                  onPressed: () => context.push(cookPrepLocation(recipe.id)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
