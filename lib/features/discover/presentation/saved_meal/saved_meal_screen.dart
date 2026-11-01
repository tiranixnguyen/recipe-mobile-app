import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_button.dart';
import 'package:recipe_mobile_app/core/widgets/app_chip.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/availability_badge.dart';
import 'package:recipe_mobile_app/core/widgets/empty_state.dart';
import 'package:recipe_mobile_app/core/widgets/meal_mosaic.dart';
import 'package:recipe_mobile_app/core/widgets/recipe_cover.dart';
import 'package:recipe_mobile_app/core/widgets/search_field.dart';
import 'package:recipe_mobile_app/core/widgets/shopping_fab.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/domain/meal_detail.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved_meal/saved_meal_view_model.dart';
import 'package:recipe_mobile_app/features/discover/routes.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Chi tiết một bữa (prototype `MealDetail`): ảnh ghép, các món (đổi, bỏ, thêm), nguyên liệu cả
/// bữa so với Tủ đồ, nút Đi chợ; dưới cùng "Thêm vào thực đơn" và "Bắt đầu nấu".
class SavedMealScreen extends ConsumerWidget {
  const SavedMealScreen({super.key, required this.mealKey});

  final String mealKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return switch (ref.watch(savedMealViewModelProvider(mealKey))) {
      AsyncData(value: final state?) => _MealDetail(mealKey: mealKey, state: state),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            icon: AppIcons.bookmark,
            title: DiscoverStrings.savedMealNotFound,
            actionLabel: DiscoverStrings.savedMealBack,
            onAction: () => context.go(savedLocation()),
          ),
        ),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            DiscoverStrings.loadError,
            style: AppTextStyles.body.copyWith(color: colors.inkMuted),
          ),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _MealDetail extends ConsumerWidget {
  const _MealDetail({required this.mealKey, required this.state});

  final String mealKey;
  final MealDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(savedMealViewModelProvider(mealKey).notifier);

    void showChange(MealChange change) {
      AppSnackbar.show(
        context,
        switch (change.kind) {
          MealChangeKind.added => DiscoverStrings.dishAdded(change.name),
          MealChangeKind.removed => DiscoverStrings.dishRemoved(change.name),
          MealChangeKind.swapped => DiscoverStrings.dishSwapped(change.from!, change.name),
        },
        action: SnackAction(DiscoverStrings.savedUndo, change.undo),
        besideFab: true,
      );
    }

    Future<void> openPicker({String? swapId}) async {
      swapId == null ? viewModel.openAdd() : viewModel.openSwap(swapId);
      final change = await showModalBottomSheet<MealChange>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _PickerSheet(mealKey: mealKey),
      );
      viewModel.closePicker();
      if (change != null && context.mounted) showChange(change);
    }

    Future<void> remove(String id) async {
      final change = await viewModel.remove(id);
      if (change != null && context.mounted) showChange(change);
    }

    Future<void> toggleSave() async {
      final outcome = await viewModel.toggleSave();
      if (outcome != null && context.mounted) {
        AppSnackbar.show(
          context,
          DiscoverStrings.savedUnsaved(outcome.name),
          action: SnackAction(DiscoverStrings.savedUndo, outcome.undo),
          besideFab: true,
        );
      }
    }

    Future<void> addMissing() async {
      final result = await viewModel.addMissingToShopping();
      if (!context.mounted || result.added == 0) return;
      AppSnackbar.show(
        context,
        DiscoverStrings.addedToShopping(result.added, result.skipped),
        action: SnackAction(DiscoverStrings.seeShopping, () => context.push(shoppingLocation)),
        besideFab: true,
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(state: state, onToggleSave: toggleSave),
                Expanded(
                  child: ListView(
                    // Chừa đáy để nút nổi Đi chợ không che nguyên liệu cuối.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s2,
                      AppSpacing.s4,
                      96,
                    ),
                    children: [
                      _Overview(state: state),
                      const SizedBox(height: AppSpacing.s5),
                      _Dishes(
                        state: state,
                        onSwap: (id) => openPicker(swapId: id),
                        onRemove: remove,
                        onAdd: openPicker,
                      ),
                      const SizedBox(height: AppSpacing.s5),
                      _Ingredients(state: state, onAddMissing: addMissing),
                    ],
                  ),
                ),
              ],
            ),
            // Nút Đi chợ nằm trong body thay vì `floatingActionButton`: màn này là Scaffold gốc, có FAB
            // thì snackbar bị đẩy lên trên nút. Đặt thế này snackbar nằm sát footer, `besideFab` chừa
            // chỗ bên phải cho nút như ở Tủ đồ.
            Positioned(
              right: AppSpacing.s4,
              bottom: AppSpacing.s4,
              child: ShoppingFab<Object>(
                count: state.shoppingCount,
                onPressed: () => context.push(shoppingLocation),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _Footer(
        onAddToPlan: () => viewModel.addToPlan(
          (dishes) => showAddMealToPlanSheet(context, dishes),
        ),
        onStart: () {
          if (viewModel.startCooking() case final location?) context.push(location);
        },
      ),
    );
  }
}

/// Nút quay lại, "Bữa của bạn" kèm dòng meta, bookmark lưu / bỏ lưu bữa.
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.onToggleSave});

  final MealDetailState state;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go(savedLocation()),
            tooltip: DiscoverStrings.savedMealBackLabel,
            icon: const Icon(AppIcons.back),
            style: IconButton.styleFrom(fixedSize: const Size.square(48)),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    DiscoverStrings.savedMealTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(color: colors.ink),
                  ),
                ),
                Text(
                  DiscoverStrings.mealDetailMeta(state.dishes.length, state.minutes, state.tools),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleSave,
            tooltip: state.saved ? DiscoverStrings.unsaveMeal : DiscoverStrings.saveMeal,
            isSelected: state.saved,
            icon: Icon(AppIcons.bookmark, fill: state.saved ? 1 : 0, color: colors.chili),
            style: IconButton.styleFrom(fixedSize: const Size.square(48)),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
    );
  }
}

/// Ảnh ghép cao 168, chip Đủ đồ / Thiếu n thứ, dòng "n người · dụng cụ".
class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final MealDetailState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final missing = state.missingIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        SizedBox(
          height: 168,
          child: MealMosaic(
            radius: AppRadius.mdAll,
            dishes: [for (final d in state.dishes) MosaicDish(d.recipe.name, d.recipe.imageAsset)],
          ),
        ),
        Row(
          spacing: AppSpacing.s2,
          children: [
            _Tag(
              missing == 0 ? AvailabilityBadge.ready : DiscoverStrings.mealStatusMissing(missing),
              tone: missing == 0 ? _TagTone.ready : _TagTone.missing,
            ),
            Expanded(
              child: Text(
                DiscoverStrings.mealServingsTools(state.servings, state.tools),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _TagTone { ready, missing, inShopping }

/// Chip nhỏ nền màu: Đủ đồ (`herb`), Thiếu (`chiliSoft`), Trong đi chợ (`herbSoft`).
class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.tone});

  final String label;
  final _TagTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      _TagTone.ready => (colors.herb, Colors.white),
      _TagTone.missing => (colors.chiliSoft, colors.chiliDeep),
      _TagTone.inShopping => (colors.herbSoft, colors.herbInk),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.smAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: foreground),
        ),
      ),
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

/// Khung `surfaceRaised` viền [border] chứa [children] cách nhau bằng đường kẻ.
class _Box extends StatelessWidget {
  const _Box({required this.children, this.border});

  final List<Widget> children;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border.all(color: border ?? colors.line),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// "Các món trong bữa (n)": mỗi món một hàng (mở Chi tiết món, Đổi, bỏ), nút gạch đứt "Thêm món".
class _Dishes extends StatelessWidget {
  const _Dishes({
    required this.state,
    required this.onSwap,
    required this.onRemove,
    required this.onAdd,
  });

  final MealDetailState state;
  final ValueChanged<String> onSwap;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s2,
      children: [
        _SectionTitle(DiscoverStrings.mealDishesTitle(state.dishes.length)),
        _Box(
          children: [
            for (final dish in state.dishes)
              _DishRow(
                dish: dish,
                canRemove: state.canRemove,
                onSwap: () => onSwap(dish.recipe.id),
                onRemove: () => onRemove(dish.recipe.id),
              ),
          ],
        ),
        _AddDishButton(onPressed: onAdd),
      ],
    );
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({
    required this.dish,
    required this.canRemove,
    required this.onSwap,
    required this.onRemove,
  });

  final MealDish dish;
  final bool canRemove;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = dish.recipe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        spacing: AppSpacing.s2,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: DiscoverStrings.dishLinkLabel(recipe.name, dish.availability.missing),
              excludeSemantics: true,
              onTap: () => context.push(recipeLocation(recipe.id)),
              child: InkWell(
                onTap: () => context.push(recipeLocation(recipe.id)),
                borderRadius: AppRadius.smAll,
                child: Row(
                  spacing: AppSpacing.s3,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: SizedBox.square(
                        dimension: 56,
                        child: RecipeCover(imageAsset: recipe.imageAsset, aspectRatio: 1),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.s1,
                        children: [
                          Text(
                            recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.button.copyWith(color: colors.ink),
                          ),
                          Text(
                            DiscoverStrings.dishRoleMeta(recipe.role.label, recipe.minutes),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                          ),
                          AvailabilityBadge(missing: dish.availability.missing),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: DiscoverStrings.swapLabel(recipe.name),
            excludeSemantics: true,
            onTap: onSwap,
            child: OutlinedButton(
              onPressed: onSwap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                foregroundColor: colors.ink,
                side: BorderSide(color: colors.outline),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.label,
              ),
              child: const Text(DiscoverStrings.swap),
            ),
          ),
          if (canRemove)
            IconButton(
              onPressed: onRemove,
              tooltip: DiscoverStrings.removeLabel(recipe.name),
              icon: const Icon(AppIcons.close, size: 20),
              style: IconButton.styleFrom(
                fixedSize: const Size.square(40),
                foregroundColor: colors.inkMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Nút viền gạch đứt "Thêm món".
class _AddDishButton extends StatelessWidget {
  const _AddDishButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      foregroundPainter: _DashedBorder(color: colors.outline, radius: AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.s2,
            children: [
              Icon(AppIcons.plus, size: 20, color: colors.chiliDeep),
              Text(
                DiscoverStrings.mealAddDish,
                style: AppTextStyles.button.copyWith(color: colors.chiliDeep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(paint.strokeWidth / 2),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 10) {
        canvas.drawPath(metric.extractPath(at, at + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color || old.radius != radius;
}

/// "Nguyên liệu cả bữa": Còn thiếu (kèm nút thêm vào đi chợ), Có trong tủ (dòng cuối là gia vị
/// cơ bản), Tuỳ chọn.
class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.state, required this.onAddMissing});

  final MealDetailState state;
  final VoidCallback onAddMissing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ingredients = state.ingredients;
    final missingCount = state.missingIds.length;
    final toAdd = state.toAddIds.length;
    final spices = ingredients.basicSpices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s2,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: _SectionTitle(DiscoverStrings.mealIngredients)),
            const SizedBox(width: AppSpacing.s3),
            Text(
              DiscoverStrings.mealServings(state.servings),
              style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
        if (missingCount > 0) ...[
          Text(
            DiscoverStrings.missingTitle(missingCount),
            style: AppTextStyles.meta.copyWith(color: colors.chiliDeep),
          ),
          _Box(
            border: colors.chiliSoft,
            children: [
              for (final line in ingredients.missing)
                _IngredientLine(
                  line: line,
                  tag: _Tag(
                    line.inShopping ? DiscoverStrings.tagInShopping : DiscoverStrings.tagMissing,
                    tone: line.inShopping ? _TagTone.inShopping : _TagTone.missing,
                  ),
                ),
            ],
          ),
          AppButton.secondary(
            label: toAdd == 0
                ? DiscoverStrings.allMissingInShopping
                : DiscoverStrings.addMissing(toAdd),
            icon: AppIcons.basket,
            block: true,
            onPressed: toAdd == 0 ? null : onAddMissing,
          ),
        ],
        if (ingredients.have.isNotEmpty || spices.isNotEmpty) ...[
          Text(
            DiscoverStrings.haveTitle,
            style: AppTextStyles.meta.copyWith(color: colors.herbInk),
          ),
          _Box(
            children: [
              for (final line in ingredients.have) _IngredientLine(line: line),
              if (spices.isNotEmpty) _SpicesLine(spices: spices),
            ],
          ),
        ],
        if (ingredients.optional.isNotEmpty) ...[
          Text(
            DiscoverStrings.optionalTitle,
            style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
          ),
          _Box(children: [for (final line in ingredients.optional) _IngredientLine(line: line)]),
        ],
      ],
    );
  }
}

class _IngredientLine extends StatelessWidget {
  const _IngredientLine({required this.line, this.tag});

  final MealIngredient line;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        spacing: AppSpacing.s3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.name} · ${line.amountText}',
                  style: AppTextStyles.body.copyWith(color: colors.ink),
                ),
                Text(
                  line.uses,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          ?tag,
        ],
      ),
    );
  }
}

class _SpicesLine extends StatelessWidget {
  const _SpicesLine({required this.spices});

  final List<String> spices;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body.copyWith(color: context.colors.inkMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s3,
        children: [
          Expanded(child: Text(spices.join(', '), style: style)),
          Text(DiscoverStrings.basicSpices, style: style),
        ],
      ),
    );
  }
}

/// "Thêm vào thực đơn" mở sheet của Thực đơn; "Bắt đầu nấu" sang Chuẩn bị nấu cả bữa.
class _Footer extends StatelessWidget {
  const _Footer({required this.onAddToPlan, required this.onStart});

  final VoidCallback onAddToPlan;
  final VoidCallback onStart;

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
                  label: DiscoverStrings.savedMealAddToPlan,
                  icon: AppIcons.calendar,
                  block: true,
                  onPressed: onAddToPlan,
                ),
              ),
              Expanded(
                flex: 5,
                child: AppButton(
                  label: DiscoverStrings.startCooking,
                  block: true,
                  onPressed: onStart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet chọn món để thêm hoặc đổi: tìm, lọc theo loại, "Món bạn đã lưu" trước rồi "Tất cả món".
/// Chọn xong thì đóng sheet và trả [MealChange].
class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet({required this.mealKey});

  final String mealKey;

  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = savedMealViewModelProvider(widget.mealKey);
    final state = ref.watch(provider).value;
    final picker = state?.picker;
    if (state == null || picker == null) return const SizedBox.shrink();
    final viewModel = ref.read(provider.notifier);

    Future<void> pick(Recipe recipe) async {
      final change = picker.swapId == null
          ? await viewModel.add(recipe.id)
          : await viewModel.swap(picker.swapId!, recipe.id);
      if (context.mounted) Navigator.of(context).pop(change);
    }

    final swapped = picker.swapId == null
        ? null
        : state.dishes.where((d) => d.recipe.id == picker.swapId).firstOrNull?.recipe;
    final title = swapped == null
        ? DiscoverStrings.pickAddTitle
        : DiscoverStrings.pickSwapTitle(swapped.name);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            0,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.s3,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(color: colors.ink),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: DiscoverStrings.pickClose,
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
              SearchField(
                controller: _query,
                onChanged: viewModel.setQuery,
                placeholder: DiscoverStrings.pickSearch,
                label: DiscoverStrings.pickSearch,
              ),
              Semantics(
                container: true,
                label: DiscoverStrings.pickFilterLabel,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: AppSpacing.s2,
                    children: [
                      AppChip(
                        label: DiscoverStrings.pickAll,
                        selected: picker.role == null,
                        onTap: () => viewModel.setRole(null),
                      ),
                      for (final role in pickerRoles)
                        AppChip(
                          label: role.label,
                          selected: picker.role == role,
                          onTap: () => viewModel.setRole(role),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: state.groups.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s4),
                        child: Text(
                          DiscoverStrings.pickNone,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(color: colors.inkMuted),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final group in state.groups) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.s1),
                              child: Text(
                                group.saved
                                    ? DiscoverStrings.pickGroupSaved
                                    : DiscoverStrings.pickGroupAll,
                                style: AppTextStyles.meta.copyWith(color: colors.inkMuted),
                              ),
                            ),
                            for (final item in group.items)
                              _PickTile(
                                item: item,
                                saved: group.saved,
                                onTap: item.inMeal ? null : () => pick(item.recipe),
                              ),
                          ],
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

class _PickTile extends StatelessWidget {
  const _PickTile({required this.item, required this.saved, required this.onTap});

  final PickItem item;
  final bool saved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = item.recipe;
    final missing = item.availability.missing;
    final meta = DiscoverStrings.dishRoleMeta(recipe.role.label, recipe.minutes);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: DiscoverStrings.pickLabel(recipe.name, item.inMeal, missing),
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
        opacity: item.inMeal ? 0.45 : 1,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.line)),
            ),
            child: Row(
              spacing: AppSpacing.s3,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: SizedBox.square(
                    dimension: 44,
                    child: RecipeCover(imageAsset: recipe.imageAsset, aspectRatio: 1),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          if (saved)
                            Icon(AppIcons.bookmark, size: 14, fill: 1, color: colors.chili),
                          Expanded(
                            child: Text(
                              recipe.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.button.copyWith(color: colors.ink),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.inMeal ? '$meta · ${DiscoverStrings.pickInMeal}' : meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
                _Tag(
                  missing.isEmpty
                      ? DiscoverStrings.pickReady
                      : DiscoverStrings.pickMissing(missing.length),
                  tone: missing.isEmpty ? _TagTone.ready : _TagTone.missing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
