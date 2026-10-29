import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';
import 'package:recipe_mobile_app/core/widgets/shopping_fab.dart';

void main() {
  final badge = find.byKey(const ValueKey('shopping-fab-badge'));

  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      late List<String> accepted;
      late int presses;

      setUp(() {
        accepted = [];
        presses = 0;
      });

      Future<void> pump(
        WidgetTester tester, {
        int count = 3,
        bool Function(String)? onWillAccept,
        bool target = true,
      }) => tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 16,
                  children: [
                    for (final item in ['egg', 'salt'])
                      HoldDraggable<String>(
                        data: item,
                        semanticsActionLabel: 'Thêm $item vào đi chợ',
                        onSemanticsAction: () => accepted.add('a11y:$item'),
                        child: Chip(label: Text(item)),
                      ),
                  ],
                ),
              ),
            ),
            floatingActionButton: target
                ? ShoppingFab<String>(
                    count: count,
                    onPressed: () => presses++,
                    onWillAccept: onWillAccept,
                    onAccept: accepted.add,
                  )
                : ShoppingFab<String>(count: count, onPressed: () => presses++),
          ),
        ),
      );

      testWidgets('tròn 56 nền chili, icon giỏ, tooltip Đi chợ, badge viền chili', (tester) async {
        await pump(tester);

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
        expect(fab.backgroundColor, colors.chili);
        expect(fab.tooltip, 'Đi chợ');
        expect(tester.getSize(find.byType(FloatingActionButton)), const Size(56, 56));
        expect(find.byIcon(AppIcons.basket), findsOneWidget);

        final box = tester.widget<Container>(badge).decoration! as BoxDecoration;
        expect(box.color, colors.surfaceRaised);
        expect((box.border! as Border).top.color, colors.chili);
        expect(tester.widget<Text>(find.text('3')).style!.color, colors.chiliDeep);
        expect(find.bySemanticsLabel('Đi chợ, 3 thứ cần mua'), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        expect(presses, 1);
      });

      testWidgets('0 thứ thì ẩn badge', (tester) async {
        await pump(tester, count: 0);
        expect(badge, findsNothing);
        expect(find.bySemanticsLabel('Đi chợ'), findsOneWidget);
      });

      testWidgets('nhấn giữ kéo chip thả vào nút thì nhận', (tester) async {
        await pump(tester);
        final gesture = await tester.startGesture(tester.getCenter(find.text('egg')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(AppDrag.active.value, 'egg');
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
          1.15,
          reason: 'đang kéo thì nút nổi to',
        );

        await gesture.moveTo(tester.getCenter(find.byType(FloatingActionButton)));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(accepted, ['egg']);
        expect(AppDrag.active.value, isNull);
        expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      });

      testWidgets('onWillAccept false thì không nhận', (tester) async {
        await pump(tester, onWillAccept: (item) => item != 'salt');
        final gesture = await tester.startGesture(tester.getCenter(find.text('salt')));
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.moveTo(tester.getCenter(find.byType(FloatingActionButton)));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(accepted, isEmpty);
      });

      testWidgets('vuốt trước 350ms là không kéo', (tester) async {
        await pump(tester);
        final gesture = await tester.startGesture(tester.getCenter(find.text('egg')));
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(tester.getCenter(find.byType(FloatingActionButton)));
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(AppDrag.active.value, isNull);
        expect(accepted, isEmpty);
      });

      testWidgets('không truyền onAccept thì không phải đích thả', (tester) async {
        await pump(tester, target: false);
        expect(find.byType(DragTarget<String>), findsNothing);
      });

      testWidgets('trình đọc màn hình dùng hành động thay cho kéo', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester);
        final node = tester.getSemantics(find.byType(HoldDraggable<String>).first);
        final action = CustomSemanticsAction(label: 'Thêm egg vào đi chợ');
        expect(node.getSemanticsData().customSemanticsActionIds, [
          CustomSemanticsAction.getIdentifier(action),
        ]);
        node.owner!.performAction(
          node.id,
          SemanticsAction.customAction,
          CustomSemanticsAction.getIdentifier(action),
        );
        expect(accepted, ['a11y:egg']);
        semantics.dispose();
      });
    });
  }

  testWidgets('360dp, chữ 1.3: badge 2 chữ số không tràn', (tester) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          floatingActionButton: ShoppingFab<String>(count: 12, onPressed: () {}),
        ),
      ),
    );
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
