import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_step/meal_step_view_model.dart';
import 'package:recipe_mobile_app/features/cook/presentation/widgets/cook_layout.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Một việc ở chặng "Sơ chế cả bữa" (prototype `MealCookStep`, `prepTasks`), đọc từ trái sang phải:
/// ô tick → tag nguyên liệu → cách làm → tag lượng căn phải.
///
/// - Cách làm ngắn nằm cạnh tag nguyên liệu; không vừa một dòng (đo bằng `TextPainter`) thì xuống
///   dòng dưới tag, tối đa 3 dòng.
/// - Dưới là tag món; nhiều món cùng cách làm thì từng cặp `[Món] [~2 tép]` không bị tách.
/// - Việc cha (các món làm khác cách): tag nguyên liệu và tổng lượng, ô tick ba trạng thái, bên
///   dưới là việc con.
/// - Tick xong thì cách làm và tag lượng gạch ngang, chuyển `inkMuted`.
class PrepTaskTile extends StatelessWidget {
  const PrepTaskTile({
    super.key,
    required this.item,
    required this.checkedOf,
    required this.onToggle,
  });

  final PrepItem item;

  /// Trạng thái ô tick của một việc: null là lửng (việc cha mới xong một phần).
  final bool? Function(PrepItem item) checkedOf;
  final ValueChanged<PrepItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    final checked = checkedOf(item);
    if (item.children.isEmpty) {
      return _Tappable(
        onTap: () => onToggle(item),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        checkbox: _Box(value: checked, onChanged: () => onToggle(item)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            _Head(
              ingredient: item.ingredient,
              action: item.action,
              amount: item.amountText,
              done: checked == true,
            ),
            if (item.dishes.isNotEmpty) _DishTags(dishes: item.dishes),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tappable(
          onTap: () => onToggle(item),
          padding: const EdgeInsets.only(top: AppSpacing.s3, bottom: AppSpacing.s1),
          checkbox: _Box(value: checked, tristate: true, onChanged: () => onToggle(item)),
          child: _Head(
            ingredient: item.ingredient,
            action: '',
            amount: item.amountText,
            done: checked == true,
          ),
        ),
        Padding(
          // Việc con thẳng hàng với tag nguyên liệu: ô tick 24 + khoảng 10.
          padding: const EdgeInsets.only(left: 34, bottom: AppSpacing.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in item.children)
                _Tappable(
                  onTap: () => onToggle(child),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
                  checkbox: _Box(value: checkedOf(child), onChanged: () => onToggle(child)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.s1,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.s2,
                        children: [
                          Expanded(
                            child: _Action(text: child.action, done: checkedOf(child) == true),
                          ),
                          _AmountTag(text: child.amountText, done: checkedOf(child) == true),
                        ],
                      ),
                      if (child.dishes.isNotEmpty) _DishTags(dishes: child.dishes),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vùng bấm cả dòng (ô tick bên trái, nội dung bên phải), gộp ngữ nghĩa để trình đọc màn hình đọc
/// một lần kèm trạng thái tick.
class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.onTap,
    required this.padding,
    required this.checkbox,
    required this.child,
  });

  final VoidCallback onTap;
  final EdgeInsets padding;
  final Widget checkbox;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                checkbox,
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.value, required this.onChanged, this.tristate = false});

  final bool? value;
  final bool tristate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: 24,
      child: Checkbox(
        value: value,
        tristate: tristate,
        onChanged: (_) => onChanged(),
        activeColor: colors.herb,
        side: BorderSide(color: colors.outline, width: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Hàng đầu của việc: tag nguyên liệu, cách làm (nếu vừa một dòng), tag lượng căn phải. Cách làm
/// không vừa thì xuống dòng riêng ngay dưới, tối đa 3 dòng.
class _Head extends StatelessWidget {
  const _Head({
    required this.ingredient,
    required this.action,
    required this.amount,
    required this.done,
  });

  final String ingredient;
  final String action;
  final String amount;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Hai tag có padding ngang 8 mỗi bên; giữa các phần cách 8.
        final room =
            constraints.maxWidth -
            (widthOf(ingredient, _IngredientTag.style) + AppSpacing.s4) -
            (widthOf(amount, _AmountTag.style) + AppSpacing.s4) -
            AppSpacing.s2 * 2;
        final inline = action.isEmpty || widthOf(action, _Action.style) <= room;
        // Vừa một dòng thì cả ba phần đã đo là đủ chỗ; không thì tag nguyên liệu co lại, cắt "…".
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.s2,
          children: [
            if (inline && action.isNotEmpty) ...[
              _IngredientTag(text: ingredient),
              Expanded(
                child: _Action(text: action, done: done, maxLines: 1),
              ),
            ] else ...[
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _IngredientTag(text: ingredient),
                ),
              ),
            ],
            _AmountTag(text: amount, done: done),
          ],
        );
        if (inline) return row;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            row,
            _Action(text: action, done: done),
          ],
        );
      },
    );
  }
}

class _IngredientTag extends StatelessWidget {
  const _IngredientTag({required this.text});

  final String text;

  static final style = AppTextStyles.caption.copyWith(
    height: 18 / 12,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.chiliSoft, borderRadius: AppRadius.pillAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(color: colors.chiliDeep),
        ),
      ),
    );
  }
}

/// Tag lượng: không viền, nền `surface`, chữ `ink` 13/18 đậm 600.
class _AmountTag extends StatelessWidget {
  const _AmountTag({required this.text, required this.done});

  final String text;
  final bool done;

  static const style = AppTextStyles.label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface, borderRadius: AppRadius.smAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 1),
        child: Text(
          text,
          style: style.copyWith(
            color: done ? colors.inkMuted : colors.ink,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: colors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.text, required this.done, this.maxLines = 3});

  final String text;
  final bool done;
  final int maxLines;

  static const style = AppTextStyles.body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(
        color: done ? colors.inkMuted : colors.ink,
        decoration: done ? TextDecoration.lineThrough : null,
        decorationColor: colors.inkMuted,
      ),
    );
  }
}

/// Tag món dưới việc; có phần lượng thì cặp `[Món] [~2 tép]` đi liền, không tách khi xuống dòng.
class _DishTags extends StatelessWidget {
  const _DishTags({required this.dishes});

  final List<({String name, String? share})> dishes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s1,
      runSpacing: AppSpacing.s1,
      children: [
        for (final dish in dishes)
          switch (dish.share) {
            null => DishTag(text: dish.name),
            final share => Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.s1,
              children: [
                Flexible(child: DishTag(text: dish.name)),
                DishTag(text: CookStrings.prepShare(share)),
              ],
            ),
          },
      ],
    );
  }
}
