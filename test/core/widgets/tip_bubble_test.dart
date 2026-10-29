import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_snackbar.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';

void main() {
  const tip = 'Nhấn giữ một nguyên liệu rồi kéo thả vào giỏ để thêm vào đi chợ.';

  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    group('theme $name', () {
      late InMemoryLocalStore store;
      late BuildContext ctx;

      setUp(() => store = InMemoryLocalStore());

      Future<void> pump(WidgetTester tester, {TipAnchor anchor = TipAnchor.none}) =>
          tester.pumpWidget(
            ProviderScope(
              overrides: [localStoreProvider.overrideWith((ref) => store)],
              child: MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: Builder(
                    builder: (context) {
                      ctx = context;
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: TipBubble(id: 'pantry.drag', text: tip, anchor: anchor),
                      );
                    },
                  ),
                ),
              ),
            ),
          );

      testWidgets('nền ink, "Mẹo:" in đậm, nút Ẩn mẹo', (tester) async {
        await pump(tester);

        final box = tester.widget<DecoratedBox>(
          find.descendant(of: find.byType(TipBubble), matching: find.byType(DecoratedBox)).first,
        );
        expect((box.decoration as BoxDecoration).color, colors.ink);
        final rich = tester.widget<Text>(
          find.ancestor(
            of: find.textContaining('Mẹo:', findRichText: true),
            matching: find.byType(Text),
          ),
        );
        expect(rich.style!.color, colors.surface);
        final prefix = (rich.textSpan! as TextSpan).children!.first as TextSpan;
        expect(prefix.text, 'Mẹo: ');
        expect(prefix.style!.fontWeight, FontWeight.w700);
        expect(
          tester.getSemantics(find.byType(IconButton)),
          matchesSemantics(
            tooltip: 'Ẩn mẹo',
            isButton: true,
            hasTapAction: true,
            isEnabled: true,
            hasEnabledState: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        expect(find.byKey(const ValueKey('tip-arrow')), findsNothing);
      });

      testWidgets('anchor right có mũi tên', (tester) async {
        await pump(tester, anchor: TipAnchor.right);
        expect(find.byKey(const ValueKey('tip-arrow')), findsOneWidget);
      });

      testWidgets('bấm ✕ thì ghi app.tipsSeen, dựng lại không hiện nữa', (tester) async {
        await pump(tester);
        await tester.tap(find.text('✕'));
        await tester.pump();

        expect(find.textContaining('Mẹo:', findRichText: true), findsNothing);
        expect(store.readList('app.tipsSeen'), ['pantry.drag']);

        await tester.pumpWidget(const SizedBox());
        await pump(tester);
        expect(find.textContaining('Mẹo:', findRichText: true), findsNothing);
      });

      testWidgets('ẩn khi đang có snackbar, hiện lại khi snackbar tắt', (tester) async {
        await pump(tester);
        AppSnackbar.show(ctx, 'Đã thêm trứng gà vào đi chợ');
        await tester.pumpAndSettle();
        expect(find.textContaining('Mẹo:', findRichText: true), findsNothing);

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.textContaining('Mẹo:', findRichText: true), findsOneWidget);
      });
    });
  }

  testWidgets('360dp, chữ 1.3 không tràn', (tester) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 88, 16),
              child: TipBubble(id: 'x', text: tip, anchor: TipAnchor.right),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
