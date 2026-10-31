import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_icon.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';

void main() {
  group('savedIdsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
      );
    });

    tearDown(() => container.dispose());

    test('toggle lưu rồi bỏ lưu, giữ thứ tự lưu, dựng lại vẫn còn', () async {
      final saved = container.read(savedIdsProvider.notifier);
      await saved.toggle('a');
      await saved.toggle('b');
      await saved.toggle('c');
      await saved.toggle('b');

      expect(container.read(savedIdsProvider).toList(), ['a', 'c']);
      expect(container.read(localStoreProvider).readList('discover.saved'), ['a', 'c']);

      container.invalidate(savedIdsProvider);
      expect(container.read(savedIdsProvider).toList(), ['a', 'c']);
    });

    test('save và unsave rõ ràng không bị đảo trạng thái nhầm', () async {
      final saved = container.read(savedIdsProvider.notifier);
      await saved.save('x');
      await saved.save('x'); // Gọi lại không đổi
      expect(container.read(savedIdsProvider), {'x'});

      await saved.unsave('x');
      await saved.unsave('x'); // Gọi lại không lỗi
      expect(container.read(savedIdsProvider), isEmpty);
    });

    test('xoá dữ liệu đưa về rỗng', () async {
      await container.read(savedIdsProvider.notifier).toggle('a');
      await container.read(clearLocalDataProvider)();
      expect(container.read(savedIdsProvider), isEmpty);
    });
  });

  for (final (name, theme, colors) in [
    ('sáng', AppTheme.light, AppColors.light),
    ('tối', AppTheme.dark, AppColors.dark),
  ]) {
    testWidgets('SaveButton theme $name: bấm thì lưu, tô đặc màu chili', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
          child: MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(child: SaveButton(recipeId: 'a')),
            ),
          ),
        ),
      );

      Icon icon() => tester.widget<Icon>(find.byIcon(AppIcons.bookmark));
      Color? color() =>
          tester.widget<IconButton>(find.byType(IconButton)).style!.foregroundColor!.resolve({});

      expect(icon().fill, 0);
      expect(color(), colors.ink);
      expect(find.byTooltip('Lưu món'), findsOneWidget);

      await tester.tap(find.byType(SaveButton));
      await tester.pump();
      expect(icon().fill, 1);
      expect(color(), colors.chili);
      expect(find.byTooltip('Bỏ lưu món'), findsOneWidget);

      await tester.tap(find.byType(SaveButton));
      await tester.pump();
      expect(icon().fill, 0);
    });
  }
}
