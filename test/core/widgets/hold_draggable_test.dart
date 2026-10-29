import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/hold_draggable.dart';

void main() {
  late List<String> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      },
    );
  });

  Future<void> pump(WidgetTester tester, {required ValueNotifier<bool> show}) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (context, visible, _) => visible
                  ? HoldDraggable<String>(
                      data: 'egg',
                      semanticsActionLabel: 'Thêm vào đi chợ',
                      onSemanticsAction: () {},
                      child: const Chip(label: Text('Trứng gà')),
                    )
                  : const SizedBox(height: 48),
            ),
            const SizedBox(height: 200),
            DragTarget<String>(
              onAcceptWithDetails: (_) => show.value = false,
              builder: (context, _, _) =>
                  const SizedBox(key: Key('target'), width: 100, height: 100),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('nhấc lên rung và đặt AppDrag.active, thả ra ngoài thì về null', (tester) async {
    final show = ValueNotifier(true);
    await pump(tester, show: show);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Trứng gà')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(AppDrag.active.value, 'egg');
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: find.text('Trứng gà').first, matching: find.byType(Opacity)),
          )
          .opacity,
      .35,
    );

    await gesture.moveBy(const Offset(200, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(AppDrag.active.value, isNull);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);
  });

  testWidgets('thả trúng đích: rung selectionClick, về null kể cả khi chip bị gỡ', (tester) async {
    final show = ValueNotifier(true);
    await pump(tester, show: show);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Trứng gà')));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveTo(tester.getCenter(find.byKey(const Key('target'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Trứng gà'), findsNothing);
    expect(AppDrag.active.value, isNull);
    expect(haptics, ['HapticFeedbackType.mediumImpact', 'HapticFeedbackType.selectionClick']);
  });

  testWidgets('chip bị gỡ giữa lúc kéo rồi thả ra ngoài vẫn về null', (tester) async {
    final show = ValueNotifier(true);
    await pump(tester, show: show);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Trứng gà')));
    await tester.pump(const Duration(milliseconds: 400));
    show.value = false;
    await tester.pump();
    await gesture.moveBy(const Offset(200, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(AppDrag.active.value, isNull);
  });
}
