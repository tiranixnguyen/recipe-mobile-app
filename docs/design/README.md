# Thiết kế — Bếp Hoà Lạc

Bản sao trong repo của hai artifact thiết kế trên claude.ai, để cả team và các agent (Claude Code, Zed, Antigravity…) đọc được mà không cần đăng nhập.

| Phần | Thư mục | Bản gốc (cần quyền xem trên claude.ai) |
|---|---|---|
| Design system | [`design-system/`](design-system/) | https://claude.ai/artifact/KMviZS2qvYfCv3YdyvCYsn |
| Prototype Android (29 màn) | [`prototype/`](prototype/) | https://claude.ai/artifact/8Bxj3zhHYamZgfue2wXUii |

> **Nguồn sự thật là artifact.** Thư mục này là ảnh chụp tại thời điểm sync (2026-10-29, bản v2). Sửa thiết kế trên artifact rồi sync lại; đừng sửa tay ở đây.

## Đọc theo thứ tự nào

1. [`design-system/README.md`](design-system/README.md): giọng văn, màu, chữ, khoảng cách, sáng/tối, icon, logo, danh sách component.
2. [`design-system/tokens.json`](design-system/tokens.json): giá trị token chính xác (màu theo theme `light`/`dark`, kiểu chữ, spacing, radius), mỗi token có `usage`. Đây là nguồn để map sang `ThemeData`/`ColorScheme` của Flutter.
3. `design-system/components/<Tên>/README.md`: quy tắc từng component. [`components/index.d.ts`](design-system/components/index.d.ts) liệt kê props.
4. `prototype/<Màn>.dc.html`: layout, nội dung chữ, trạng thái và luồng điều hướng của từng màn.

## Design system

```
design-system/
  README.md              brand book
  tokens.json            token (màu 2 theme, typography, spacing, radius)
  design-system.json     index của artifact (namespace, asset)
  assets/Logos/          5 file SVG logo + README quy tắc dùng
  components/
    <Tên>/README.md      quy tắc dùng
    <Tên>/preview.html   bản xem trước (cần runtime của artifact)
    bundle.js / .css     cài đặt React của component — bản đặc tả, không phải code app
    index.d.ts           kiểu props
```

Component: `Button`, `Chip`, `SearchField`, `AvailabilityBadge`, `RecipeCard`, `BottomNav`, `EmptyState`, `StepTimer`, `ServingStepper`, `Icon`. Khi code Flutter, mỗi cái thành một widget tương ứng; `bundle.css` cho biết kích thước, padding, màu từng trạng thái.

## Prototype

Khung điện thoại 390×844 (riêng hai bảng logo rộng 1440, bảng `Toasts` rộng 900). Mọi màn app đều có prop `theme` (`system` | `light` | `dark`).

| Nhóm | File → tên màn |
|---|---|
| Tab chính | `Main` Khám phá · `Pantry` Tủ đồ · `MealPlan` Thực đơn · `Saved` Đã lưu (tab Món ăn / Bữa ăn, nhấn giữ kéo vào thùng rác để bỏ lưu) |
| Luồng | `Onboarding` Làm quen lần đầu · `TodayPrefs` Hôm nay ăn gì, chọn nhu cầu · `Today` Hôm nay ăn gì (gợi ý theo bữa) · `Search` Tìm kiếm · `Detail` Chi tiết món · `Shopping` Danh sách đi chợ · `AddToPlan` Thêm vào thực đơn (chọn ngày, bữa; một bữa nhiều món) |
| Nấu | `CookPrep` Chuẩn bị · `CookStep` Từng bước · `CookDone` Hoàn thành |
| Nấu cả bữa | `MealCookPrep` Chuẩn bị cả bữa, thứ tự món · `MealCookStep` Từng bước, chuyển món · `MealCookDone` Xong, chấm từng món. Mở từ Thực đơn ("Nấu bữa này") và mục "Sắp tới bữa … rồi" ở Khám phá. Hôm nay ăn gì không nấu thẳng: Lưu lại hoặc Thêm vào thực đơn |
| Hệ thống | `Splash` Khởi động · `NotifPermission` Xin quyền thông báo · `Settings` Cài đặt (Sáng/Tối/Hệ thống) · `About` Giới thiệu · `Policy` Chính sách quyền riêng tư · `Feedback` Góp ý & báo lỗi · `RateApp` Đánh giá trên Google Play · `ClearData` Xoá dữ liệu (gõ `CONFIRM DELETE`) · `Error` Lỗi (biến thể `crash`/`notfound`/`storage`) |
| Dùng chung | `Toasts` Thông báo chung: snackbar, mẹo, banner trong màn, hộp thoại xác nhận (khung 900 rộng) |
| Logo | `Logo` 4 hướng (đã chọn C) · `LogoC` Bát & đũa — bộ nhận diện |

[`prototype/canvas.json`](prototype/canvas.json) giữ tên, vị trí và thứ tự các màn trên canvas.

### Cách đọc file `.dc.html`

- Markup trong `<x-dc>` là giao diện; `{{tên}}` lấy giá trị từ `renderVals()` trong khối `<script type="text/x-dc">` cuối file. Dữ liệu mẫu (món, bước nấu, nguyên liệu) nằm ở đầu khối script đó.
- `<x-import component-from-global-scope="BepHoaLac.Button" …>` là component của design system; `<sc-for>` là vòng lặp, `<sc-if>` là điều kiện.
- `<a href="Khác.dc.html">` là điều hướng giữa các màn — dùng để dựng route trong app.
- Token CSS (`--surface`, `--chili`…) khai báo trong `<helmet><style>` của từng file, trùng với `tokens.json`.
- `prototype/ds/bep-hoa-lac/` là bản design system được nhúng vào canvas (giống hệt `design-system/` cùng tên file), giữ lại để đường dẫn tương đối trong `.dc.html` còn đúng.
- File cần `support.js` của runtime artifact nên **mở trực tiếp trên trình duyệt sẽ không chạy**. Muốn xem bản tương tác, mở link artifact ở trên.

## Sync lại sau khi sửa artifact

Nhờ Claude Code (có quyền xem 2 artifact): *"sync lại docs/design từ artifact design system và prototype"*. Nó sẽ đọc file `project/` của từng artifact rồi ghi đè vào đây, giữ nguyên cấu trúc thư mục này. Logo nằm trong kho asset của artifact design system, tên file lấy từ `design-system.json` → `assetGroups.Logos`.
