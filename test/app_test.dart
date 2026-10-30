import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_mobile_app/app/app.dart';
import 'package:recipe_mobile_app/app/splash_screen.dart';
import 'package:recipe_mobile_app/app/theme_preview_screen.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/theme/theme.dart';
import 'package:recipe_mobile_app/core/widgets/app_logo.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_screen.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_screen.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_screen.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/pantry/presentation/pantry/pantry_screen.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/presentation/plan/plan_screen.dart';
import 'package:recipe_mobile_app/features/system/data/app_info.dart';
import 'package:recipe_mobile_app/features/system/presentation/settings/settings_screen.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'features/cook/fakes.dart';
import 'features/cook/fixtures.dart';

/// Dữ liệu đóng gói đọc bằng `rootBundle` không xong trong fake async của widget test, màn có
/// spinner sẽ làm `pumpAndSettle` treo; dữ liệu thật đã có `bundled_data_test.dart`.
final _dataOverrides = [
  recipesProvider.overrideWith((ref) async => const <Recipe>[]),
  ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
];

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('lần đầu: Splash → Onboarding → Khám phá, chuyển được 4 tab', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: _dataOverrides, child: const App()));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Bếp Hoà Lạc'), findsOneWidget);

    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    expect(find.text('Phòng bạn có gì để nấu?'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DiscoverScreen), findsOneWidget);

    await tester.tap(_tab('Tủ đồ'));
    await tester.pumpAndSettle();
    expect(find.byType(PantryScreen), findsOneWidget);

    await tester.tap(_tab('Thực đơn'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);

    await tester.tap(_tab('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedScreen), findsOneWidget);
  });

  testWidgets('Onboarding: chọn dụng cụ, chế độ ăn rồi Xong thì lưu và vào Khám phá', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(overrides: _dataOverrides, child: const App()));
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nồi cơm điện'));
    await tester.tap(find.text('Không ăn cay'));
    await tester.pump();
    await tester.tap(find.text('Xong, gợi ý món cho mình'));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoverScreen), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
    expect(
      container.read(kitchenProfileProvider),
      const KitchenProfile(tools: {Tool.rice}, diets: {Diet.nospicy}),
    );
  });

  testWidgets('đã qua Onboarding: Splash vào thẳng Khám phá', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._dataOverrides, localStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Phòng bạn có gì để nấu?'), findsNothing);
  });

  testWidgets('chưa qua Onboarding: mở thẳng route khác vẫn bị đưa về Onboarding', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: _dataOverrides, child: const App()));

    GoRouter.of(tester.element(find.byType(SplashScreen))).go('/pantry');
    await tester.pumpAndSettle();

    expect(find.text('Phòng bạn có gì để nấu?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('màn toàn màn hình mở bằng push, back về lại shell', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._dataOverrides, localStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(NavigationBar))).push(searchLocation());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DiscoverScreen), findsOneWidget);
  });

  testWidgets('chọn theme Tối thì app dùng theme tối từ token', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._dataOverrides, localStoreProvider.overrideWithValue(store)],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(NavigationBar)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.dark.surface);
  });

  testWidgets('trang xem theme mở được trước Onboarding, có cả hai theme', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: _dataOverrides, child: const App()));

    GoRouter.of(tester.element(find.byType(SplashScreen))).go(themePreviewLocation);
    await tester.pumpAndSettle();

    expect(find.byType(ThemePreviewScreen), findsOneWidget);
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Tối'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cài đặt: đổi giao diện và sửa dụng cụ & chế độ ăn', (tester) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._dataOverrides,
          localStoreProvider.overrideWithValue(store),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(NavigationBar))).push(settingsLocation);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.dark);
    expect(find.text('App luôn dùng giao diện Tối.'), findsOneWidget);

    await tester.tap(find.text('Dụng cụ & chế độ ăn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lò vi sóng'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
    expect(container.read(kitchenProfileProvider).tools, {Tool.micro});
    expect(container.read(onboardingDoneProvider), isTrue);

    await tester.scrollUntilVisible(find.text('Bếp Hoà Lạc · phiên bản 1.0.0'), 200);
    expect(find.text('Xoá dữ liệu trên máy'), findsOneWidget);
  });

  testWidgets(
    'Thực đơn → mở bữa trưa → Chi tiết → Thêm vào Trưa mai → Thực đơn mở ngày mai có món',
    (
      tester,
    ) async {
      const recipe = Recipe(
        id: 'trung',
        name: 'Trứng chiên hành',
        description: '',
        imageAsset: '',
        minutes: 15,
        servings: 1,
        tools: [Tool.stove],
        diets: [],
        meals: [],
        ingredients: [],
        steps: [RecipeStep(text: 'Chiên trứng')],
      );
      final store = InMemoryLocalStore();
      await store.writeString('system.onboarded', 'true');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipesProvider.overrideWith((ref) async => const [recipe]),
            ingredientsProvider.overrideWith((ref) async => const <Ingredient>[]),
            localStoreProvider.overrideWithValue(store),
            // 17h Thứ Ba.
            nowProvider.overrideWithValue(DateTime(2026, 10, 20, 17)),
          ],
          child: const App(),
        ),
      );
      await tester.pump(SplashScreen.duration);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
      await container
          .read(plannedMealsProvider.notifier)
          .addToPlan('trung', DateTime(2026, 10, 20), Meal.lunch);

      await tester.tap(_tab('Thực đơn'));
      await tester.pumpAndSettle();
      // 17h: bữa tâm điểm là Tối; bữa trưa thu gọn, bấm để mở.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Trưa: 1 món')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Trứng chiên hành'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trứng chiên hành'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('Thêm vào thực đơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('T4'));
      await tester.tap(find.text('Trưa'));
      await tester.pump();
      await tester.tap(find.text('Thêm vào Trưa mai'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsNothing);
      expect(find.byType(PlanScreen), findsOneWidget);
      expect(find.text('Thứ Tư, 21/10'), findsOneWidget);
      // Mở đúng bữa vừa thêm.
      expect(find.text('Trứng chiên hành'), findsOneWidget);
      expect(find.text('1 món · ~15 phút'), findsOneWidget);
      expect(
        container.read(plannedMealsProvider).map((p) => (p.day, p.meal)),
        [(DateTime(2026, 10, 20), Meal.lunch), (DateTime(2026, 10, 21), Meal.lunch)],
      );

      // Về hôm nay vẫn thấy bữa trưa cũ.
      await tester.tap(find.byTooltip('Ngày trước'));
      await tester.pumpAndSettle();
      expect(find.text('Thứ Ba, 20/10 · Hôm nay'), findsOneWidget);
      expect(find.text('Trứng chiên hành'), findsOneWidget);
    },
  );

  testWidgets('Chi tiết → Chuẩn bị đổi khẩu phần → qua từng bước → Hoàn thành cập nhật tủ', (
    tester,
  ) async {
    final store = InMemoryLocalStore();
    await store.writeString('system.onboarded', 'true');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipesProvider.overrideWith((ref) async => const [cookRecipeFixture]),
          ingredientsProvider.overrideWith((ref) async => cookIngredientsFixture),
          localStoreProvider.overrideWithValue(store),
          wakelockProvider.overrideWithValue(FakeWakelock()),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          shouldAskNotificationPermissionProvider.overrideWithValue(() async => false),
          appInForegroundProvider.overrideWithValue(() => true),
          appReviewProvider.overrideWithValue(FakeAppReview()),
        ],
        child: const App(),
      ),
    );
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
    for (final id in ['egg', 'scallion']) {
      await container.read(pantryItemsProvider.notifier).addToPantry(id);
    }

    GoRouter.of(tester.element(find.byType(NavigationBar))).push(recipeLocation('trung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CookStrings.startCooking));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Thêm một người'));
    await tester.pump();
    expect(find.text('Trứng gà · 4 quả'), findsOneWidget);
    await tester.tap(find.text(CookStrings.startCooking).last);
    await tester.pumpAndSettle();
    // Chưa tick "Lấy đồ ra": sheet hỏi lại.
    await tester.tap(find.text(CookStrings.confirmStartCooking));
    await tester.pumpAndSettle();

    expect(find.text('Bước 1/4'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(CookStrings.nextStep));
      await tester.pumpAndSettle();
    }
    expect(find.text('Bước 4/4'), findsOneWidget);
    // Sau bước cuối là trang Lưu ý cách dùng, nút Xong ở đó.
    await tester.tap(find.text(CookStrings.nextStep));
    await tester.pumpAndSettle();
    expect(find.text(CookStrings.notesTitle), findsOneWidget);
    await tester.tap(find.text(CookStrings.finish));
    await tester.pumpAndSettle();

    // Màn Xong: chấm điểm, ghi chú, rồi sang PantryUpdate.
    expect(find.text(CookStrings.doneTitle), findsOneWidget);
    await tester.tap(find.text(CookStrings.doneNoteToPantry));
    await tester.pumpAndSettle();

    // Màn PantryUpdate: đồ đã dùng hiển thị, bỏ tick trứng gà.
    expect(find.text(CookStrings.pantryUpdateTitle), findsOneWidget);
    expect(find.text('Đã dùng 4 quả'), findsOneWidget);
    await tester.tap(find.text('Trứng gà').first);
    await tester.pump();
    await tester.tap(find.text(CookStrings.pantryUpdateFinish));
    await tester.pumpAndSettle();

    expect(container.read(pantryItemsProvider), {'scallion'});
    expect(container.read(cookHistoryProvider).single.recipeId, 'trung');
    expect(container.read(cookSessionProvider), isNull);
  });
}
