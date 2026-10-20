# RecipeCard

Thẻ công thức trong lưới hoặc danh sách: ảnh, tên món, thời gian, khẩu phần, dụng cụ và đủ/thiếu đồ.

- Nền `surface-raised`, viền `line`, bo `radius-md`, padding `space-4`. Ảnh tỉ lệ 16:10; chưa có ảnh thì hiện hình bát trên nền `chili-soft`.
- Dòng meta style `meta`, màu `ink-muted`: `15 phút · 1 người · Bếp từ`.
- Truyền `missing` (mảng, có thể rỗng) để hiện AvailabilityBadge; bỏ trống khi màn hình không biết tủ đồ.
- Nút bookmark (lưu) chỉ hiện khi truyền `onToggleSave`; trạng thái lưu qua `saved`, đã lưu thì tô đặc màu `chili`.
- Tên món tối đa 2 dòng, viết đúng tiếng Việt có dấu. Người dùng cung cấp `title`, `minutes`, `servings`, `tool`, `missing`, `image`.
