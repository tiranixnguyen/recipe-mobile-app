# recipe_mobile_app

App công thức nấu ăn giá rẻ cho sinh viên khu Hoà Lạc (ĐH FPT, ĐHQG…).

> Trạng thái: project khởi tạo để các thành viên clone & chạy thử.

## Yêu cầu

- [FVM](https://fvm.app) ≥ 4.x — Flutter SDK được pin trong `.fvmrc` (hiện tại **3.47.5**)
- Android Studio (Android SDK + emulator) và/hoặc Xcode (macOS, cho iOS)

## Setup

```bash
git clone <repo-url> && cd recipe-mobile-app
fvm install            # cài đúng Flutter version theo .fvmrc, tạo .fvm/flutter_sdk
fvm flutter pub get
fvm flutter doctor     # kiểm tra môi trường
fvm flutter run        # chạy trên emulator/thiết bị đang kết nối
```

Luôn dùng `fvm flutter …` / `fvm dart …` thay vì `flutter` global để cả team cùng version.

## Cấu hình IDE

Formatter dùng chung khai báo trong `analysis_options.yaml` (`page_width: 100`), nên IDE nào format cũng ra cùng kết quả.

| IDE | Cần làm |
|---|---|
| **VS Code** | Mở project → cài extension được gợi ý. `.vscode/settings.json` đã trỏ SDK tới `.fvm/flutter_sdk`. |
| **Antigravity** | Giống VS Code (đọc cùng `.vscode/`). Cài extension *Dart* + *Flutter* nếu chưa có. |
| **Zed** | Cài extension *Dart*. Zed dùng `dart` trên `PATH`, nên đảm bảo `PATH` trỏ tới SDK của FVM, ví dụ thêm vào shell: `export PATH="$HOME/fvm/default/bin:$PATH"` sau khi chạy `fvm global 3.47.5`. |
| **Android Studio** | Cài plugin *Flutter*. *Settings → Languages & Frameworks → Flutter → Flutter SDK path* = `<project>/.fvm/flutter_sdk`. Thư mục `.idea/` không được commit. |

## Lệnh hay dùng

```bash
fvm dart format .                       # format code
fvm flutter analyze                     # lint
fvm flutter test                        # chạy test
```
