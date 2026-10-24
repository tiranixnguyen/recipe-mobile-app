import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';

void main() {
  test('nhãn thời lượng và mm:ss', () {
    expect(StepTimer.durationLabel(180), '3 phút');
    expect(StepTimer.durationLabel(45), '45 giây');
    expect(StepTimer.durationLabel(90), '01:30');
    expect(StepTimer.mmss(165), '02:45');
  });

  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      late DateTime now;
      late List<StepTimerStatus> statuses;
      late int dones;

      Future<void> pump(WidgetTester tester, {int seconds = 180, bool autoStart = false}) {
        now = DateTime(2026, 10, 24, 18);
        statuses = [];
        dones = 0;
        return tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: StepTimer(
                  seconds: seconds,
                  label: 'Chiên mặt dưới',
                  autoStart: autoStart,
                  clock: () => now,
                  onStatusChange: statuses.add,
                  onDone: () => dones++,
                ),
              ),
            ),
          ),
        );
      }

      Color barColor(WidgetTester tester) =>
          (tester.widget<Container>(find.byType(Container).first).decoration! as BoxDecoration)
              .color!;

      testWidgets('chờ → đang chạy → hết giờ → tắt', (tester) async {
        await pump(tester);
        expect(find.text('Hẹn 3 phút'), findsOneWidget);

        await tester.tap(find.text('Hẹn 3 phút'));
        await tester.pump();
        expect(statuses, [StepTimerStatus.running]);
        expect(find.text('03:00'), findsOneWidget);
        expect(find.text('Chiên mặt dưới'), findsOneWidget);
        expect(find.text('Dừng'), findsOneWidget);
        expect(barColor(tester), colors.ink);
        final time = tester.widget<Text>(find.text('03:00'));
        expect(time.style!.fontSize, 28);
        expect(time.style!.fontWeight, FontWeight.w700);

        // Đồng hồ hệ thống nhảy 15 giây (vd. app ở nền) thì số hiện theo giờ thật.
        now = now.add(const Duration(seconds: 15));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('02:45'), findsOneWidget);

        now = now.add(const Duration(seconds: 165));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Xong!'), findsOneWidget);
        expect(find.text('Hết giờ · Chiên mặt dưới'), findsOneWidget);
        expect(barColor(tester), colors.chili);
        expect(statuses, [StepTimerStatus.running, StepTimerStatus.done]);
        expect(dones, 1);

        await tester.tap(find.text('Tắt'));
        await tester.pump();
        expect(find.text('Hẹn 3 phút'), findsOneWidget);
        expect(statuses.last, StepTimerStatus.idle);
      });

      testWidgets('Dừng khi đang chạy thì về chờ, không gọi onDone', (tester) async {
        await pump(tester, seconds: 45, autoStart: true);
        expect(find.text('00:45'), findsOneWidget);

        await tester.tap(find.text('Dừng'));
        await tester.pump();
        expect(find.text('Hẹn 45 giây'), findsOneWidget);

        now = now.add(const Duration(minutes: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(dones, 0);
      });
    });
  }
}
