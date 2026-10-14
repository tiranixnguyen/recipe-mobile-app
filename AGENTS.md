# AGENTS.md

Hướng dẫn chung cho mọi AI agent (Antigravity, Claude Code, Zed…) và cho người. Đọc hết trước khi code.

> Nhánh `demo`: app "Trà sữa Hoà Lạc" thu nhỏ để minh hoạ flow làm việc. Không merge vào `main`.

## Sản phẩm

- Flutter, **chỉ Android**. Không sửa gì trong `ios/`.
- **Không có đăng nhập.** Dữ liệu cá nhân chỉ lưu trên máy qua `LocalStore`.
- Giao diện tiếng Việt.

## Lệnh

Luôn dùng `fvm`, không dùng `flutter` global.

```bash
fvm flutter pub get
fvm dart format lib test
fvm flutter analyze
fvm flutter test
fvm flutter run            # chạy trên emulator/máy Android
```

## Kiến trúc

```
lib/
  main.dart              # khởi tạo, override provider thật
  app/                   # router, shell, theme — Lead
  core/                  # model, repository, LocalStore, widget dùng chung — Lead
  features/<f>/
    <f>.dart             # PUBLIC API — thứ duy nhất feature khác được import
    routes.dart          # route của feature, app/router.dart gộp lại
    strings.dart         # chuỗi UI của feature
    domain/              # hàm thuần, không import Flutter — bắt buộc có unit test
    data/                # provider/notifier, đọc ghi LocalStore
    presentation/        # màn hình, widget
```

- State: Riverpod (`Provider`, `FutureProvider`, `NotifierProvider`), không codegen.
- Điều hướng: go_router. Đi tới màn của feature khác bằng hàm trong public API của nó
  (ví dụ `context.push(drinkLocation(id))`), không tự ghép chuỗi đường dẫn.
- Tiền là `int` VND, hiển thị qua `formatVnd`.

## Ranh giới feature (quan trọng)

1. Chỉ sửa file trong `lib/features/<feature của issue>/` và `test/features/<feature của issue>/`.
2. Dùng feature khác **chỉ** qua `lib/features/<f>/<f>.dart`. Không import file bên trong feature khác.
3. Cần sửa `lib/core/`, `lib/app/`, `pubspec.yaml` → **dừng lại**, ghi vào PR/issue để Lead làm.
4. Key `LocalStore` có tiền tố tên feature: `favorites.ids`, `pantry.items`…
5. Khi feature khác cần thứ mình làm: công bố **stub** trong public API trước (chạy được, chưa có logic),
   làm bản thật sau — người dùng stub không phải sửa gì.

## Quy trình làm một issue

1. Đọc issue (`gh issue view <N>`), đặc biệt Acceptance criteria và Phụ thuộc.
2. Đề xuất plan ngắn (file sẽ tạo/sửa) và **chờ người duyệt** trước khi code.
3. Code trong branch `feat/<N>-<slug>` (hoặc `fix/…`, `chore/…`).
4. Viết test: hàm trong `domain/` → unit test; màn hình → widget test.
5. Chạy `fvm dart format lib test && fvm flutter analyze && fvm flutter test` — phải sạch.
6. Mở PR theo template, có `Closes #<N>` và ảnh/quay màn hình Android.

## Definition of Done

- [ ] Đủ Acceptance criteria của issue
- [ ] Format, analyze, test sạch; CI xanh
- [ ] Chỉ sửa trong thư mục feature của mình (trừ khi issue nói khác)
- [ ] Người mở PR đã đọc lại toàn bộ code agent sinh ra
