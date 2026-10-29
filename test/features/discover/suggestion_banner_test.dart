import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/suggestion_banner.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

void main() {
  const sampleItems = [
    SuggestionBannerItem(
      title: 'Sáng nay vội?',
      description: 'Siêu tốc dưới 15 phút, ít rửa bát.',
      contextText: 'Sáng Thứ Năm',
      icon: AppIcons.clock,
      tags: ['Siêu tốc', '1 món gọn lẹ'],
    ),
    SuggestionBannerItem(
      title: 'Tủ còn trứng, cà chua',
      description: '3 món nấu được ngay, không phải đi chợ.',
      contextText: 'Dọn tủ lạnh',
      icon: AppIcons.fridge,
      tags: ['Dọn tủ lạnh'],
    ),
    SuggestionBannerItem(
      title: 'Cuối tháng rồi',
      description: 'Hệ tiết kiệm: tận dụng đồ sẵn có.',
      contextText: 'Cuối tháng',
      icon: AppIcons.sun,
      tags: ['Tiết kiệm'],
    ),
  ];

  Future<void> pumpBanner(
    WidgetTester tester, {
    List<SuggestionBannerItem> items = sampleItems,
    VoidCallback? onPreferencesTap,
    bool disableAnimations = false,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SuggestionBanner(
                items: items,
                onPreferencesTap: onPreferencesTap,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('tự chuyển sau 6 giây và quay vòng lại đầu', (tester) async {
    await pumpBanner(tester);

    expect(find.text('Sáng nay vội?'), findsOneWidget);
    expect(find.text('Tủ còn trứng, cà chua'), findsNothing);

    // Qua 6 giây -> chuyển sang thẻ 2
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Tủ còn trứng, cà chua'), findsOneWidget);
    expect(find.text('Sáng nay vội?'), findsNothing);

    // Qua tiếp 6 giây -> chuyển sang thẻ 3
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Cuối tháng rồi'), findsOneWidget);

    // Qua tiếp 6 giây -> vòng lại thẻ 1
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Sáng nay vội?'), findsOneWidget);
  });

  testWidgets('không tự chuyển khi disableAnimations = true', (tester) async {
    await pumpBanner(tester, disableAnimations: true);

    expect(find.text('Sáng nay vội?'), findsOneWidget);

    // Tua qua 12 giây
    await tester.pump(const Duration(seconds: 12));
    await tester.pump();

    // Vẫn ở thẻ 1
    expect(find.text('Sáng nay vội?'), findsOneWidget);
    expect(find.text('Tủ còn trứng, cà chua'), findsNothing);
  });

  testWidgets('chấm chỉ vị trí có nhãn trợ năng và bấm chấm đổi thẻ', (tester) async {
    await pumpBanner(tester);

    // Kiểm tra nhãn trợ năng ("Thẻ 1 trên 3", "Thẻ 2 trên 3", "Thẻ 3 trên 3")
    expect(find.bySemanticsLabel('Thẻ 1 trên 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Thẻ 2 trên 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Thẻ 3 trên 3'), findsOneWidget);

    // Bấm chấm 2
    await tester.tap(find.bySemanticsLabel('Thẻ 2 trên 3'));
    await tester.pumpAndSettle();
    expect(find.text('Tủ còn trứng, cà chua'), findsOneWidget);

    // Bấm chấm 3
    await tester.tap(find.bySemanticsLabel('Thẻ 3 trên 3'));
    await tester.pumpAndSettle();
    expect(find.text('Cuối tháng rồi'), findsOneWidget);

    // Bấm chấm 1
    await tester.tap(find.bySemanticsLabel('Thẻ 1 trên 3'));
    await tester.pumpAndSettle();
    expect(find.text('Sáng nay vội?'), findsOneWidget);
  });

  testWidgets('bấm thẻ gọi callback onTap', (tester) async {
    var tapped = 0;
    final items = [
      SuggestionBannerItem(
        title: 'Món có callback',
        description: 'Mô tả',
        onTap: () => tapped++,
      ),
    ];

    await pumpBanner(tester, items: items);

    await tester.tap(find.text('Món có callback'));
    await tester.pump();
    expect(tapped, 1);

    // Bấm nút CTA Xem món cũng gọi callback
    await tester.tap(find.text('Xem món'));
    await tester.pump();
    expect(tapped, 2);
  });

  testWidgets('bấm Gợi ý cho mình gọi callback onPreferencesTap', (tester) async {
    var prefsTapped = 0;
    await pumpBanner(tester, onPreferencesTap: () => prefsTapped++);

    await tester.tap(find.text(DiscoverStrings.heroAction));
    await tester.pump();
    expect(prefsTapped, 1);
  });

  testWidgets('dừng tự chuyển khi chạm (pointer down) và tiếp tục sau khi nhấc tay', (
    tester,
  ) async {
    await pumpBanner(tester);

    expect(find.text('Sáng nay vội?'), findsOneWidget);

    // Người dùng chạm giữ trên màn hình
    final gesture = await tester.startGesture(tester.getCenter(find.byType(SuggestionBanner)));
    await tester.pump();

    // 10 giây trôi qua trong khi vẫn đang giữ tay -> không chuyển
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(find.text('Sáng nay vội?'), findsOneWidget);
    expect(find.text('Tủ còn trứng, cà chua'), findsNothing);

    // Nhấc tay ra
    await gesture.up();
    await tester.pump();

    // Sau khi nhấc tay 6 giây -> chuyển thẻ
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Tủ còn trứng, cà chua'), findsOneWidget);
  });

  testWidgets('dừng tự chuyển khi nhận focus và tiếp tục khi mất focus', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Focus(
            focusNode: focusNode,
            child: const SuggestionBanner(
              items: sampleItems,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sáng nay vội?'), findsOneWidget);

    // Focus vào banner
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // 10 giây trôi qua trong khi đang focus -> không chuyển thẻ
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(find.text('Sáng nay vội?'), findsOneWidget);

    // Unfocus
    focusNode.unfocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    // Sau khi mất focus 6 giây -> chuyển thẻ
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Tủ còn trứng, cà chua'), findsOneWidget);
  });

  testWidgets('hủy timer khi widget bị gỡ (không rò timer)', (tester) async {
    await pumpBanner(tester);

    // Thay thế widget bằng SizedBox rỗng
    await tester.pumpWidget(const SizedBox());
    // Tua thêm 10 giây xem có timer nào rò rỉ không
    await tester.pump(const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
  });

  testWidgets('danh sách rỗng render SizedBox.shrink, danh sách 1 thẻ không lỗi timer', (
    tester,
  ) async {
    await pumpBanner(tester, items: const []);
    expect(find.byType(PageView), findsNothing);

    await pumpBanner(
      tester,
      items: const [
        SuggestionBannerItem(
          title: 'Duy nhất',
          description: 'Mô tả',
        ),
      ],
    );
    expect(find.text('Duy nhất'), findsOneWidget);
    // Tua 10 giây không có timer crash
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(find.text('Duy nhất'), findsOneWidget);
  });

  for (final (name, theme) in [
    ('sáng', AppTheme.light),
    ('tối', AppTheme.dark),
  ]) {
    testWidgets('hiển thị đúng trên theme $name', (tester) async {
      await pumpBanner(tester, theme: theme);
      expect(find.text('Sáng nay vội?'), findsOneWidget);
      expect(find.text('Siêu tốc dưới 15 phút, ít rửa bát.'), findsOneWidget);
      expect(find.text('Sáng Thứ Năm'), findsOneWidget);
      expect(find.text('Siêu tốc'), findsOneWidget);
      expect(find.text('1 món gọn lẹ'), findsOneWidget);
      expect(find.text('Xem món'), findsOneWidget);
    });
  }
}
