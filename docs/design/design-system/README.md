# Bếp Hoà Lạc

Có gì nấu nấy, ăn gì cũng có kế hoạch. Đây là ngôn ngữ hình ảnh của app công thức nấu ăn cho sinh viên khu Hoà Lạc (ĐH FPT, ĐHQG…): gợi ý món từ đồ đang có trong tủ và bếp ở phòng, rồi lên thực đơn cho một ngày hoặc cả tuần. Ấm như bếp ký túc xá, rõ ràng như một tờ danh sách đi chợ.

> Bản đầu tiên, nhỏ: repo chưa có brand, logo hay theme nào, nên toàn bộ giá trị dưới đây là đề xuất khởi điểm để team duyệt rồi đưa vào `ThemeData` của Flutter. App không hiển thị giá tiền ở bất kỳ đâu.

## App có gì

- **Bốn tab:** Khám phá · Tủ đồ · Thực đơn · Đã lưu.
- **Bốn luồng chính:** *Hôm nay ăn gì* (một món gợi ý kèm 2 món thay thế, đổi hoặc chê được); *Tủ đồ* (bật nguyên liệu đang có → món nấu được ngay / thiếu 1–2 thứ); *Thực đơn* (xem theo ngày hoặc tuần, ba bữa Sáng/Trưa/Tối, tự gợi ý cả tuần); *Đi chợ* (gom nguyên liệu của thực đơn, trừ đồ đã có trong tủ).

## Giọng văn

- Nói chuyện như bạn cùng phòng: xưng "bạn", câu ngắn, không thuật ngữ bếp sang chảnh. Ví dụ: "Trứng chiên hành — 15 phút, bếp từ".
- Luôn nói **thời gian** và **dụng cụ** trước, rồi mới đến món. Dòng meta viết `15 phút · 1 người · Bếp từ`, ngăn bằng dấu chấm giữa.
- Nói rõ đồ có sẵn hay còn thiếu: "Đủ đồ", "Thiếu: hành lá", "Có sẵn 3/3 nguyên liệu".
- Không emoji trong UI; tên món giữ đúng tiếng Việt có dấu.

## Nền tảng hình ảnh

- **Màu:** nền `surface` kem ấm, chữ `ink`. `chili` (cam ớt) là màu thương hiệu cho hành động chính và tab đang mở; `herb` (xanh rau thơm) chỉ mang nghĩa *có sẵn / nấu được ngay / thành công*, đừng dùng trang trí. Chip đang chọn và badge "Thiếu…": nền `chili-soft`, chữ `chili-deep`.
- **Chữ:** Be Vietnam Pro (Google Fonts) vì dấu tiếng Việt đẹp và đều. Dòng thời gian · khẩu phần · dụng cụ dùng style `meta`.
- **Khoảng cách:** lưới 4px; lề màn hình `space-4`, giữa các section `space-6`.
- **Hình khối:** mềm và thân thiện — thẻ, nút, ô thực đơn `radius-md`, chip `radius-pill`, badge `radius-sm`. Ô thực đơn còn trống có viền đứt `outline`. Không đổ bóng đậm; tách lớp bằng `surface-raised` trên `surface` và viền `line`.

## Sáng, tối và theo hệ thống

- Hai theme `light` và `dark`; người dùng chọn **Sáng / Tối / Theo hệ thống** trong Cài đặt, mặc định *Theo hệ thống* (Flutter: `ThemeMode.system`).
- Theme tối là nâu than ấm (`surface` #1A1410), không đen tuyền, để giữ cảm giác bếp. Nút chính vẫn nền `chili` chữ trắng.
- Trên nền tối, chữ màu thương hiệu (link, "Thiếu: …") dùng `chili-deep`, chữ màu xanh dùng `herb-ink`; `chili` và `herb` chỉ làm nền nút, badge, icon.
- Viết UI bằng token, không mã màu cứng, để đổi theme không phải sửa từng màn.
- Màu đỏ `danger` chỉ dành cho hành động không hoàn tác được. Nút `danger` để tắt cho tới khi người dùng gõ xác nhận (ví dụ `CONFIRM DELETE` khi xoá dữ liệu); chữ cảnh báo dùng `danger-ink`.

## Iconography

Dùng Material Symbols Rounded (đi cùng Flutter), nét 2px, cỡ 20/24px, màu `ink` hoặc `chili` khi đang chọn. Lưu món dùng icon bookmark (tô đặc khi đã lưu).

## Logo

Bát cơm và đôi đũa: bát nâu đậm `ink`, đũa cam `chili` gác lên miệng bát, icon app trên nền `chili-soft`. Tối giản, đọc rõ ở cỡ 24px, nói ngay "nấu ăn kiểu Việt". Trên nền tối dùng bản bát kem, đũa cam sáng. Android dùng adaptive icon (lớp trước + nền `chili-soft`) và lớp một màu cho themed icon, thông báo. File và quy tắc dùng: nhóm asset **Logos**.

## Component

Mười component, viết bằng React để xem trước ở đây; khi code Flutter, dùng chúng làm bản đặc tả cho widget tương ứng.

- **Button**: `primary` một lần mỗi màn hình; `secondary`, `ghost` cho phần còn lại.
- **Chip**: lọc theo thời gian, dụng cụ, bữa, chế độ ăn, nguyên liệu; chip đang chọn có nền `chili-soft`.
- **SearchField**: ô tìm món hoặc nguyên liệu.
- **AvailabilityBadge**: "Đủ đồ" trên `herb`, hoặc "Thiếu: …" trên `chili-soft`.
- **RecipeCard**: ảnh, tên món, thời gian, khẩu phần, dụng cụ, badge đủ/thiếu đồ và nút lưu.
- **BottomNav**: bốn tab Khám phá, Tủ đồ, Thực đơn, Đã lưu.
- **EmptyState**: khi danh sách trống, kèm một hành động gợi ý.
- **StepTimer**: hẹn giờ cho một bước nấu; nút "Hẹn 3 phút" thành thanh đếm ngược `ink`, hết giờ chuyển `chili`.
- **ServingStepper**: chỉnh khẩu phần − / +, số lượng nguyên liệu nhân theo.
- **Icon**: bộ icon nét tạm thời.

**Chế độ nấu** (Chuẩn bị → Từng bước → Hoàn thành): chữ bước 24/34, nút điều hướng dùng `Button size="lg"` (cao 56px) nằm sát đáy cho ngón cái, hẹn giờ đặt ngay trên nút, màn hình luôn sáng. Màn Hoàn thành dùng icon `bowl` trên nền `chili-soft` và ba nút đánh giá Ngon / Tạm / Chê với icon smile / meh / frown. Mỗi màn chỉ một bước, một nút `primary`.

Control có viền dùng `outline` (đạt 3:1), còn `line` chỉ để kẻ trang trí. Mọi control focus đều có vòng `chili` 2px.

## Việc tiếp theo

Logo, component cho ô thực đơn và dải chọn ngày, map token sang `ThemeData` của Flutter.
