import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/day_strip.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/confirm_sheet.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/routes.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Chuẩn bị nấu cả bữa (prototype `MealCookPrep`): thứ tự nấu, khẩu phần cả bữa, "Lấy đồ ra · cả
/// bữa"; dưới cùng "Bắt đầu sơ chế" ("Bắt đầu: tên món đầu" khi bữa không có gì để sơ chế).
class MealPrepScreen extends ConsumerWidget {
  const MealPrepScreen({super.key, required this.slot});

  final PlannedSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(mealPrepViewModelProvider(slot))) {
      AsyncData(:final value) => _MealPrep(state: value),
      AsyncError(error: MealNotFound()) => const NoMealScreen(
        message: CookStrings.mealNotFoundBody,
      ),
      AsyncError() => const NoMealScreen(message: CookStrings.loadError),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _MealPrep extends ConsumerWidget {
  const _MealPrep({required this.state});

  final MealPrepState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(mealPrepViewModelProvider(state.slot).notifier);
    final dayName = DayStrip.fullNames[state.slot.day.weekday - 1];

    Future<void> start() async {
      final router = GoRouter.of(context);
      if (!state.allGathered &&
          !await showCookConfirmSheet(
            context,
            title: CookStrings.gatherConfirmTitle,
            body: CookStrings.gatherConfirmBody(state.checkedCount, state.total),
            cancelLabel: CookStrings.gatherConfirmBack,
            confirmLabel: state.hasPrep
                ? CookStrings.confirmStartPrep
                : CookStrings.confirmStartCooking,
          )) {
        return;
      }
      if (await viewModel.shouldAskNotificationPermission()) {
        await router.push<bool>(notifPermissionLocation);
      }
      await viewModel.start();
      // Thay màn Chuẩn bị: thoát chế độ nấu thì về Thực đơn.
      router.pushReplacement(mealCookStepLocation);
    }

    Future<void> addToShopping() async {
      final router = GoRouter.of(context);
      await viewModel.addToShopping();
      router.push(shoppingLocation);
    }

    void move(int from, int to) {
      if (to < 0 || to >= state.dishes.length || to == from) return;
      viewModel.move(from, to);
      final name = state.dishes[from].recipe.name;
      SemanticsService.sendAnnouncement(
        View.of(context),
        CookStrings.movedTo(name, to + 1),
        Directionality.of(context),
      );
    }

    final spices = state.basicSpices;
    final gatherRows = [
      for (final item in state.gather)
        MealGatherRow(
          name: item.name,
          amount: item.amountText,
          dishes: [for (final id in item.recipeIds) state.nameOf(id)],
          checked: state.checked.contains(item.ingredientId),
          onChanged: () => viewModel.toggle(item.ingredientId),
        ),
      if (spices.isNotEmpty)
        MealGatherRow(
          name: spices.join(', '),
          amount: CookStrings.enough,
          checked: state.checked.contains(MealPrepViewModel.spicesKey),
          onChanged: () => viewModel.toggle(MealPrepViewModel.spicesKey),
        ),
    ];
    const side = EdgeInsets.symmetric(horizontal: AppSpacing.s4);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CookHeader(
              title: CookStrings.mealTitle(state.slot.meal),
              subtitle: state.hasPrep
                  ? CookStrings.mealPrepMeta(
                      dayName,
                      state.dishes.length,
                      state.prepMinutes,
                      state.cookMinutes,
                    )
                  : CookStrings.mealMeta(
                      dayName,
                      state.dishes.length,
                      state.minutes,
                      state.tools,
                    ),
              icon: AppIcons.back,
              tooltip: CookStrings.backToPlan,
              onPressed: () => context.canPop() ? context.pop() : context.go(planLocation()),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s2,
                      AppSpacing.s4,
                      AppSpacing.s2,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _OrderHeader(
                        reordered: state.reordered,
                        onReset: viewModel.useSuggestedOrder,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: side,
                    sliver: SliverReorderableList(
                      itemCount: state.dishes.length,
                      onReorderItem: move,
                      proxyDecorator: (child, _, _) => Material(
                        color: Colors.transparent,
                        elevation: 6,
                        borderRadius: AppRadius.mdAll,
                        child: child,
                      ),
                      itemBuilder: (context, i) => Padding(
                        key: ValueKey(state.dishes[i].recipe.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                        child: _OrderRow(index: i, dish: state.dishes[i], onMove: move),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s2,
                      AppSpacing.s4,
                      AppSpacing.s4,
                    ),
                    sliver: SliverList.list(
                      children: [
                        ServingsBox(
                          value: state.servings,
                          hint: CookStrings.mealServingsHint,
                          onChanged: viewModel.setServings,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        SectionHeader(
                          title: CookStrings.mealGather,
                          trailing: gatherRows.isEmpty
                              ? null
                              : CookStrings.gathered(state.checkedCount, state.total),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        if (gatherRows.isNotEmpty) RowsBox(rows: gatherRows),
                        if (state.missing.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s3),
                          MissingBox(
                            missing: [for (final m in state.missing) m.name],
                            notes: state.notes,
                            onAddToShopping: addToShopping,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CookFooter(
              child: AppButton(
                label: state.hasPrep
                    ? CookStrings.startPrep
                    : CookStrings.startFirst(state.dishes.first.recipe.name),
                size: AppButtonSize.lg,
                block: true,
                onPressed: start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Thứ tự nấu · Giữ và kéo để đổi thứ tự", bên phải "Dùng thứ tự gợi ý" khi đã đổi.
class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.reordered, required this.onReset});

  final bool reordered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      spacing: AppSpacing.s2,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  CookStrings.cookOrder,
                  style: AppTextStyles.subtitle.copyWith(color: colors.ink),
                ),
              ),
              Text(
                CookStrings.cookOrderHint,
                style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        if (reordered)
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: colors.chiliDeep,
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: AppTextStyles.label,
            ),
            child: const Text(CookStrings.useSuggestedOrder),
          ),
      ],
    );
  }
}

/// Một món trong "Thứ tự nấu": số thứ tự tròn 28, tên (tối đa 2 dòng), thời gian · dụng cụ, tay
/// cầm kéo. Tay cầm nhận phím mũi tên lên/xuống để đổi thứ tự không cần kéo.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.index, required this.dish, required this.onMove});

  final int index;
  final MealDish dish;

  /// Đổi món ở vị trí `from` sang vị trí `to`.
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = dish.recipe;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s3, 10, AppSpacing.s1, 10),
        child: Row(
          spacing: AppSpacing.s3,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.chiliSoft, shape: BoxShape.circle),
              child: Text(
                '${index + 1}',
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.chiliDeep,
                ),
              ),
            ),
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
                  Text(
                    recipeMeta(recipe),
                    style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: _Grip(
                label: CookStrings.reorderLabel(recipe.name, index + 1),
                onUp: () => onMove(index, index - 1),
                onDown: () => onMove(index, index + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tay cầm kéo 48×48 lấy focus được: mũi tên lên/xuống đổi thứ tự; viền `chili` khi có focus.
class _Grip extends StatefulWidget {
  const _Grip({required this.label, required this.onUp, required this.onDown});

  final String label;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  State<_Grip> createState() => _GripState();
}

class _GripState extends State<_Grip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          widget.onUp();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onDown();
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Tooltip(
        message: widget.label,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: _focused ? Border.all(color: colors.chili, width: 2) : null,
          ),
          child: Icon(Symbols.drag_indicator_rounded, color: colors.inkMuted),
        ),
      ),
    );
  }
}

/// Không có bữa để nấu (bữa đã bị xoá khỏi Thực đơn, phiên nấu đã xong): mời mở Thực đơn.
class NoMealScreen extends StatelessWidget {
  const NoMealScreen({super.key, this.message = CookStrings.noMealBody});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: EmptyState(
        title: CookStrings.noMealTitle,
        message: message,
        actionLabel: CookStrings.toPlan,
        onAction: () => context.go(planLocation()),
      ),
    ),
  );
}
