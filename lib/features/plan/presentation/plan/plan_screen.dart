import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/confirm_dialog.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/calendar_sheet.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_view_model.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/recipe_picker_sheet.dart';
import 'package:recipe_mobile_app/features/plan/routes.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Thực đơn (prototype `MealPlan`): chế độ Ngày với một bữa tâm điểm; chế độ Tuần chờ #48.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key, this.initialDate, this.initialMeal, this.openRequest});

  /// Ngày mở sẵn (`/plan?date=2026-10-30`, sau khi thêm món); null là giữ ngày đang xem.
  final DateTime? initialDate;

  /// Bữa mở sẵn của [initialDate] (`&meal=dinner`).
  final Meal? initialMeal;

  /// `extra` của lần điều hướng ([goToPlanDay]); đổi thì mở lại [initialDate] dù ngày không đổi.
  final Object? openRequest;

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    _showInitialDate();
  }

  @override
  void didUpdateWidget(PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tab giữ màn khi chuyển tab, nên `go(planLocation(date: …))` lần sau tới đây. So cả
    // [openRequest] vì thêm món vào cùng ngày lần nữa thì URL không đổi.
    if (widget.initialDate != oldWidget.initialDate ||
        widget.initialMeal != oldWidget.initialMeal ||
        !identical(widget.openRequest, oldWidget.openRequest)) {
      _showInitialDate();
    }
  }

  /// Đổi state của ViewModel sau frame, Riverpod không cho sửa provider lúc đang dựng cây widget.
  void _showInitialDate() {
    final date = widget.initialDate;
    if (date == null) return;
    final meal = widget.initialMeal;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(planViewModelProvider.notifier).selectDate(date, meal: meal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(planViewModelProvider);
    final value = state.value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(state: value),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) => _Body(state: value),
                AsyncError() => Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Text(
                    PlanStrings.loadError,
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

/// "Thực đơn", công tắc Ngày | Tuần, nút lịch.
class _Header extends ConsumerWidget {
  const _Header({required this.state});

  final PlanState? state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = this.state;
    final viewModel = ref.read(planViewModelProvider.notifier);

    Future<void> openCalendar(PlanState state) async {
      final date = await showCalendarSheet(
        context,
        selected: state.selectedDate,
        today: state.today,
      );
      if (date != null) viewModel.selectDate(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s2,
        AppSpacing.s1,
      ),
      child: Row(
        spacing: AppSpacing.s2,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                PlanStrings.title,
                style: AppTextStyles.title.copyWith(color: colors.ink),
              ),
            ),
          ),
          if (state != null)
            IconButton(
              onPressed: () => openCalendar(state),
              tooltip: PlanStrings.calendarLabel(state.title),
              icon: const Icon(AppIcons.calendar),
              color: colors.ink,
            ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.state});

  final PlanState state;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sang ngày khác thì đọc từ đầu, tiêu đề ngày không bị cuộn khuất.
    if (widget.state.selectedDate != oldWidget.state.selectedDate && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final colors = context.colors;
    final viewModel = ref.read(planViewModelProvider.notifier);
    final week = state.mode == PlanMode.week;

    Future<void> suggestDay() async {
      final added = await viewModel.suggestDay();
      if (added == 0 && context.mounted) _showSuggestNone(context);
    }

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s1,
        AppSpacing.s4,
        AppSpacing.s5,
      ),
      children: [
        Row(
          spacing: AppSpacing.s1,
          children: [
            Transform.translate(
              offset: const Offset(-AppSpacing.s2, 0),
              child: IconButton(
                onPressed: viewModel.previous,
                tooltip: week ? PlanStrings.previousWeek : PlanStrings.previousDay,
                icon: const Icon(Symbols.chevron_left_rounded, size: 22),
                color: colors.ink,
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  state.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(AppSpacing.s2, 0),
              child: IconButton(
                onPressed: viewModel.next,
                tooltip: week ? PlanStrings.nextWeek : PlanStrings.nextDay,
                icon: const Icon(Symbols.chevron_right_rounded, size: 22),
                color: colors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        if (week)
          // TODO(#48): lưới cả tuần, "Đã lên n/21 bữa", "Gợi ý cả tuần".
          Text(
            PlanStrings.weekComingSoon,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          )
        else ...[
          if (state.dayEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Center(
                child: AppButton.ghost(label: PlanStrings.suggestDay, onPressed: suggestDay),
              ),
            ),
          for (final meal in Meal.values) ...[
            if (meal != Meal.values.first) const SizedBox(height: AppSpacing.s2),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: meal == state.focusMeal
                  ? _OpenMeal(key: ValueKey(('open', meal)), state: state, meal: meal)
                  : _CollapsedMeal(
                      key: ValueKey(('collapsed', meal)),
                      meal: meal,
                      summary: state.summaries[meal]!,
                      dishes: state.meals[meal]!,
                      cooked: state.cookedMeals.contains(meal),
                      onTap: () => viewModel.focus(meal),
                    ),
            ),
          ],
        ],
      ],
    );
  }
}

void _showSuggestNone(BuildContext context) =>
    AppSnackbar.show(context, PlanStrings.suggestNone, kind: SnackKind.info, besideFab: true);

/// Bữa thu gọn: một hàng tên bữa, tóm tắt, tối đa 3 ảnh nhỏ, "+N", mũi tên xuống.
class _CollapsedMeal extends StatelessWidget {
  const _CollapsedMeal({
    super.key,
    required this.meal,
    required this.summary,
    required this.dishes,
    required this.cooked,
    required this.onTap,
  });

  final Meal meal;
  final String summary;
  final List<PlannedDish> dishes;
  final bool cooked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final thumbs = dishes.take(3).toList();
    return Semantics(
      button: true,
      expanded: false,
      label: PlanStrings.openMeal(meal.label, summary),
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.line),
          borderRadius: AppRadius.mdAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, AppSpacing.s2, AppSpacing.s2, AppSpacing.s2),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.s2,
                          children: [
                            Text(
                              meal.label,
                              style: AppTextStyles.button.copyWith(color: colors.ink),
                            ),
                            if (cooked) _CookedLabel(meal: meal),
                          ],
                        ),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  if (thumbs.isNotEmpty)
                    SizedBox(
                      width: 32 + 22.0 * (thumbs.length - 1),
                      height: 32,
                      child: Stack(
                        children: [
                          for (final (i, dish) in thumbs.indexed)
                            Positioned(
                              left: 22.0 * i,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.smAll,
                                  border: Border.all(color: colors.surfaceRaised, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                                  child: _Thumb(imageAsset: dish.recipe.imageAsset),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (dishes.length > 3)
                    Text(
                      '+${dishes.length - 3}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Icon(Symbols.expand_more_rounded, size: 20, color: colors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ảnh nhỏ 28 của món trong bữa thu gọn; chưa có ảnh thì là ô `line`.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: context.colors.line);
    return imageAsset.isEmpty
        ? placeholder
        : Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => placeholder,
          );
  }
}

/// Bữa tâm điểm: viền `chili` 2px, tên bữa và meta, nút Nấu, card từng món, Thêm món.
class _OpenMeal extends ConsumerWidget {
  const _OpenMeal({super.key, required this.state, required this.meal});

  final PlanState state;
  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewModel = ref.read(planViewModelProvider.notifier);
    final dishes = state.meals[meal]!;
    final date = state.selectedDate;

    final cooked = state.cookedMeals.contains(meal);

    Future<bool> confirmIfCooked({required String message, required String confirmLabel}) async {
      if (!cooked) return true;
      return showConfirmDialog(
        context,
        title: PlanStrings.cookedConfirmTitle,
        message: message,
        confirmLabel: confirmLabel,
      );
    }

    Future<void> add() async {
      final ok = await confirmIfCooked(
        message: PlanStrings.confirmAddWhenCooked,
        confirmLabel: PlanStrings.confirmAddLabel,
      );
      if (!ok || !context.mounted) return;
      final id = await showRecipePicker(context, meal);
      if (id != null) await viewModel.addDish(meal, id);
    }

    Future<void> suggest() async {
      final added = await viewModel.suggestMeal(meal);
      if (added == 0 && context.mounted) _showSuggestNone(context);
    }

    Future<void> act(_DishAction action, Recipe recipe) async {
      switch (action) {
        case _DishAction.swap:
          final id = await showRecipePicker(context, meal);
          if (id != null) await viewModel.swapDish(meal, recipe.id, id);
        case _DishAction.remove:
          final removed = await viewModel.removeDish(meal, recipe.id);
          if (removed == null || !context.mounted) return;
          AppSnackbar.show(
            context,
            PlanStrings.removed(recipe.name, meal),
            action: SnackAction(PlanStrings.undo, () => viewModel.undoRemove(removed)),
          );
      }
    }

    Future<void> cook() async {
      final ok = await confirmIfCooked(
        message: PlanStrings.confirmCookWhenCooked,
        confirmLabel: PlanStrings.confirmCookLabel,
      );
      if (!ok || !context.mounted) return;
      context.push(mealCookLocation(date, meal));
    }

    final Widget? cookWidget = dishes.isEmpty
        ? null
        : _CookButton(
            text: PlanStrings.cookMeal,
            label: PlanStrings.cookMealLabel(meal, [for (final d in dishes) d.recipe.name]),
            onPressed: cook,
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: PlanStrings.mealSection(meal, state.dayWord),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s3, 14, AppSpacing.s3, AppSpacing.s3),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.chili, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s3,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                spacing: AppSpacing.s2,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            meal.label,
                            style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                          ),
                        ),
                        Text(
                          state.metas[meal]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  if (cooked) _CookedLabel(meal: meal),
                  ?cookWidget,
                ],
              ),
            ),
            for (final dish in dishes)
              _DishCard(
                recipe: dish.recipe,
                onOpen: () => context.push(recipeLocation(dish.recipe.id)),
                onAction: (action) => act(action, dish.recipe),
              ),
            if (dishes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, AppSpacing.s2, 2, 0),
                child: Text(
                  PlanStrings.emptyMeal(meal, state.dayWord),
                  style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                ),
              ),
            _AddDishButton(onPressed: add),
            if (dishes.isEmpty)
              AppButton.secondary(label: PlanStrings.suggestMeal, block: true, onPressed: suggest),
          ],
        ),
      ),
    );
  }
}

enum _DishAction { swap, remove }

/// Card món trong bữa tâm điểm: ảnh 2:1, tên 2 dòng, meta; nút ⋯ mở menu Đổi món / Bỏ khỏi bữa.
class _DishCard extends StatelessWidget {
  const _DishCard({required this.recipe, required this.onOpen, required this.onAction});

  final Recipe recipe;
  final VoidCallback onOpen;
  final ValueChanged<_DishAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.line),
            borderRadius: AppRadius.mdAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecipeCover(imageAsset: recipe.imageAsset, aspectRatio: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s3,
                    10,
                    AppSpacing.s3,
                    AppSpacing.s3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                      ),
                      Text(
                        recipeMeta(recipe),
                        style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.s2,
          right: AppSpacing.s2,
          child: PopupMenuButton<_DishAction>(
            tooltip: PlanStrings.dishMenu(recipe.name),
            onSelected: onAction,
            color: colors.surfaceRaised,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colors.line),
              borderRadius: AppRadius.mdAll,
            ),
            position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _DishAction.swap,
                child: Text(
                  PlanStrings.swapDish,
                  style: AppTextStyles.body.copyWith(color: colors.ink),
                ),
              ),
              PopupMenuItem(
                value: _DishAction.remove,
                child: Text(
                  PlanStrings.removeDish,
                  style: AppTextStyles.body.copyWith(color: colors.dangerInk),
                ),
              ),
            ],
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(Symbols.more_horiz_rounded, size: 20, color: colors.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Thêm món": nút cao 52 viền đứt `outline`.
class _AddDishButton extends StatelessWidget {
  const _AddDishButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: PlanStrings.addDish,
      excludeSemantics: true,
      child: CustomPaint(
        painter: _DashedBorder(color: colors.outline),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.mdAll,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.s2,
                children: [
                  Icon(AppIcons.plus, size: 20, color: colors.ink),
                  Text(
                    PlanStrings.addDish,
                    style: AppTextStyles.button.copyWith(color: colors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Viền đứt 1.5px bo `radius-md`.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 1.5;
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()..addRRect(AppRadius.mdAll.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color;
}

/// "Nấu món này" / "Nấu bữa này": viên `chili` cao 36 (prototype `MealPlan`), vùng chạm 48.
class _CookButton extends StatelessWidget {
  const _CookButton({required this.text, required this.label, required this.onPressed});

  final String text;

  /// Nhãn cho trình đọc màn hình, kèm tên các món.
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.pillAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              decoration: BoxDecoration(color: colors.chili, borderRadius: AppRadius.pillAll),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  // Chữ trắng trên `chili` như nút chính.
                  const Icon(AppIcons.bowl, size: 16, color: Colors.white),
                  Text(text, style: AppTextStyles.label.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bữa đã nấu xong: dấu check "Đã nấu" màu `herbInk`, chỉ để hiển thị, không bấm được.
class _CookedLabel extends StatelessWidget {
  const _CookedLabel({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: PlanStrings.cooked,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(AppIcons.check, size: 16, color: colors.herbInk),
          Text(PlanStrings.cooked, style: AppTextStyles.label.copyWith(color: colors.herbInk)),
        ],
      ),
    );
  }
}
