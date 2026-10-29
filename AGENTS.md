# AGENTS.md

Hướng dẫn chung cho mọi AI agent (Antigravity, Claude Code, Zed…) và cho người. Đọc hết trước khi code.

App Flutter **Bếp Hoà Lạc**: công thức nấu ăn cho sinh viên khu Hoà Lạc, gợi ý món từ đồ có sẵn trong tủ và
dụng cụ trong phòng. Setup máy: xem `README.md`. Kế hoạch và issue: `docs/backlog.md`.

## Luật sản phẩm

- **Không hiển thị giá tiền ở bất kỳ đâu.** Không thu thập giá, không có trường giá trong dữ liệu. App gợi ý
  theo đồ có sẵn, dụng cụ và thời gian, không theo ngân sách.
- **Chỉ Android.** Không sửa gì trong `ios/`, không viết code riêng cho iOS.
- **Không tài khoản, không đăng nhập.** Dữ liệu cá nhân (tủ đồ, thực đơn, món đã lưu, lịch sử nấu, dụng cụ,
  chế độ ăn, giao diện) chỉ lưu trên máy qua `LocalStore`. Chỉ nội dung góp ý người dùng tự gửi mới rời máy.
- **Công thức đóng gói sẵn** trong `assets/data/`, app chạy offline hoàn toàn. Firebase chỉ dùng cho
  Crashlytics/Analytics và nhận góp ý. Ngoại lệ duy nhất: gợi ý theo thời tiết (#115), mặc định tắt, chỉ gọi
  mạng và xin vị trí gần đúng khi người dùng tự bật.
- Thông báo (snackbar, mẹo, banner, hộp thoại xác nhận) chỉ dùng widget chung trong `lib/core/widgets/` theo
  `docs/design/prototype/Toasts.dc.html` (#112), không tự `SnackBar(...)`.
- Giọng văn UI: tiếng Việt có dấu, xưng "bạn", câu ngắn, không emoji. Chi tiết trong
  `docs/design/design-system/README.md`.

## Lệnh

Luôn dùng `fvm`, không dùng `flutter` global.

```bash
fvm flutter pub get
fvm dart format lib test
fvm flutter analyze
fvm flutter test
fvm flutter run            # chạy trên emulator/máy Android
```

## Thiết kế

Trước khi dựng hay sửa UI, đọc [`docs/design/README.md`](docs/design/README.md).

- Màu, chữ, spacing, radius lấy từ `docs/design/design-system/tokens.json` (có theme `light` và `dark`);
  không mã màu cứng trong widget.
- Quy tắc component: `docs/design/design-system/components/<Tên>/README.md`.
- Layout, chữ hiển thị và điều hướng của từng màn: `docs/design/prototype/<Màn>.dc.html`.
- Thông báo chỉ dùng widget chung theo board `docs/design/prototype/Toasts.dc.html`: `AppSnackbar.show`
  (kết quả thao tác, Hoàn tác, lỗi thử lại được), `TipBubble` (mẹo thao tác ẩn), `InlineBanner` (trạng
  thái trong màn), `showConfirmDialog` (thao tác không hoàn tác được). Không tự `SnackBar(...)`,
  `AlertDialog`.
- `docs/design/` là bản sao từ artifact trên claude.ai; đừng sửa tay, xem mục *Sync lại* trong README đó.

## Kiến trúc (MVVM với Riverpod)

```
lib/
  main.dart              # khởi tạo, override provider thật
  app/                   # router, shell, splash, màn lỗi — Lead
  core/                  # model, repository, LocalStore, theme, widget dùng chung — Lead
  features/<f>/
    <f>.dart             # PUBLIC API — thứ duy nhất feature khác được import
    routes.dart          # route của feature, app/router.dart gộp lại
    strings.dart         # chuỗi UI của feature
    domain/              # hàm thuần, không import Flutter — bắt buộc có unit test
    data/                # state dùng chung của feature, đọc ghi LocalStore
    presentation/<màn>/
      <màn>_screen.dart      # View
      <màn>_view_model.dart  # ViewModel + class state của màn
assets/data/             # recipes.json, ingredients.json — xem docs/data-model.md
```

| Lớp | Là gì | Nằm ở |
|---|---|---|
| Model | Dữ liệu và cách lấy/lưu: `Recipe`, `RecipeRepository`, `LocalStore`, state dùng chung (`pantryItemsProvider`…) | `core/`, `features/<f>/data/` |
| ViewModel | `Notifier`/`AsyncNotifier` của **một** màn: giữ state bất biến của màn, có method cho từng thao tác | `presentation/<màn>/<màn>_view_model.dart` |
| View | `ConsumerWidget`: `ref.watch` state để vẽ, bấm thì gọi method của ViewModel | `presentation/<màn>/<màn>_screen.dart` |

1. Mỗi màn có một ViewModel. View không gọi thẳng repository hay `LocalStore`, không tự tính toán.
2. ViewModel là việc nội bộ của feature, **không** export ra `<f>.dart`. Thứ feature khác cần dùng chung đặt
   trong `data/` (tầng Model).
3. Test ViewModel bằng `ProviderContainer` (không cần dựng widget); hàm trong `domain/` bằng unit test.
4. Màn chỉ hiển thị nội dung cố định (Giới thiệu, Chính sách) không cần ViewModel.

- State: Riverpod (`Provider`, `FutureProvider`, `NotifierProvider`), không codegen, không dùng
  `ChangeNotifier`/package `provider`.
- Điều hướng: go_router. Đi tới màn của feature khác bằng hàm trong public API của nó
  (ví dụ `context.push(recipeLocation(id))`), không tự ghép chuỗi đường dẫn.
- Kiểu dùng chung (`Recipe`, `Ingredient`, `Meal`, `Tool`, `Diet`, `IngredientGroup`) nằm trong
  `lib/core/models/`. Không tự định nghĩa lại bằng `String`.

## Analytics

Ghi sự kiện bằng `ref.read(analyticsProvider).track(event, params)` (`lib/core/analytics.dart`) trong
ViewModel, không gọi từ View. Tên snake_case; tham số chỉ là số, bool hoặc chuỗi cố định — không gửi nội dung
người dùng gõ, email hay id thiết bị. Hiện là stub in ra log, bản Firebase thay sau (SET-16). Thêm sự kiện mới
thì ghi vào bảng này.

| Sự kiện | Khi nào | Tham số |
|---|---|---|
| `onboarding_done` | Lần đầu qua Onboarding (Xong hoặc Bỏ qua) | `skipped`, `tools`, `diets` (số lượng) |
| `theme_change` | Đổi Sáng/Tối/Theo hệ thống trong Cài đặt | `mode` (`light`/`dark`/`system`) |
| `feedback_send` | Gửi góp ý thành công | `kind` (`bug`/`recipe`/`other`), `screenshot`, `from_error` |
| `view_recipe` | Mở Chi tiết món | `recipe` (id món đóng gói sẵn) |
| `start_cooking` | Bấm Bắt đầu nấu (một món hoặc cả bữa) | `servings`, `steps` (tổng số bước), `meal_dishes` (số món) |
| `finish_cooking` | Xong ở màn Hoàn thành | `used_up` (số đồ tick Hết), `rated`, `meal_dishes` |
| `rate_recipe` | Mỗi món được chấm khi Xong | `rating` (`good`/`ok`/`bad`) |
| `today_suggest` | Mở màn Hôm nay ăn gì | `meal` (`breakfast`/`lunch`/`dinner`, bữa theo giờ) |
| `today_dislike` | Chọn lý do sau Không thích ở Hôm nay ăn gì | `reason` (`justAte`/`missingIngredients`/`tooLong`/`notMyTaste`) |
| `search` | Bấm tìm trên bàn phím ở màn Tìm kiếm | `has_query`, `filtered` (bool; không gửi từ khoá) |

## 5 feature

| Feature | Chủ | Thư mục | Màn (prototype) | Public API (`<f>.dart`) |
|---|---|---|---|---|
| F1 Khám phá | @hu666-dot | `features/discover` | Main, Search, TodayPrefs, Today, Saved | `SaveButton`, `savedIdsProvider`, `savedMealsProvider`, route `/search` |
| F2 Nấu | @dtranh2005 | `features/cook` | Detail, CookPrep, CookStep, CookDone, RateApp | route `/recipe/:id`, `ResumeCookingBanner`, `cookHistoryProvider` |
| F3 Tủ đồ & gợi ý | @tiranixnguyen (Lead) | `features/pantry` | Pantry | `availabilityFor`, `suggest`, `dislike`, `pantryItemsProvider`, `addToPantry`, `removeFromPantry` |
| F4 Thực đơn & đi chợ | @SeiGirl | `features/plan` | MealPlan, Shopping | `addToPlan`, `addToShopping`, `plannedMealsProvider`, route `/shopping` |
| F5 Hệ thống | @huytq160871 | `features/system` | Onboarding, Settings, NotifPermission, Feedback, About, Policy, ClearData | `kitchenProfileProvider`, `themeModeProvider`, `NotificationService` |

Lead làm `app/`, `core/` (Splash, Error, theme, dữ liệu), `pubspec.yaml`, `assets/` và review mọi widget trong
`lib/core/widgets/`. Component của design system chia theo người cần đầu tiên, xem `docs/backlog.md`.

## Ranh giới feature (quan trọng)

1. Chỉ sửa file trong `lib/features/<feature của issue>/` và `test/features/<feature của issue>/`.
2. Dùng feature khác **chỉ** qua `lib/features/<f>/<f>.dart`. Không import file bên trong feature khác.
   Import luôn bằng `package:recipe_mobile_app/...` (lint `always_use_package_imports`), không `../../`.
3. Cần sửa `lib/core/`, `lib/app/`, `pubspec.yaml`, `assets/` → **dừng lại**, ghi vào PR/issue để Lead làm.
   Ngoại lệ: issue giao component cho bạn thì được tạo file đó trong `lib/core/widgets/`.
4. Key `LocalStore` có tiền tố tên feature: `discover.saved`, `pantry.items`…
5. Khi feature khác cần thứ mình làm: công bố **stub** trong public API trước (chạy được, chưa có logic),
   làm bản thật sau, giữ nguyên chữ ký — người dùng stub không phải sửa gì.

## Quy trình làm một issue

1. Đọc issue (`gh issue view <N>`), đặc biệt Acceptance criteria và Phụ thuộc.
2. Màn có UI: đọc prototype được nhắc trong issue và README của component sẽ dùng.
3. Đề xuất plan ngắn (file sẽ tạo/sửa) và **chờ người duyệt** trước khi code.
4. Code trong branch `feat/<N>-<slug>` (hoặc `fix/…`, `chore/…`).
5. Viết test: hàm trong `domain/` → unit test; ViewModel → test với `ProviderContainer`; widget dùng chung
   trong `core/widgets/` → widget test.
6. Chạy `fvm dart format lib test && fvm flutter analyze && fvm flutter test` — phải sạch.
7. Mở PR theo template, có `Closes #<N>` và ảnh Android đặt cạnh prototype.

## Definition of Done

- [ ] Đủ Acceptance criteria của issue
- [ ] UI đúng `docs/design/`, dùng token theme, chạy đúng cả sáng và tối
- [ ] Format, analyze, test sạch; CI xanh
- [ ] Chỉ sửa trong thư mục feature của mình (trừ khi issue nói khác)
- [ ] Người mở PR đã đọc lại toàn bộ code agent sinh ra
