# ServingStepper

Chỉnh khẩu phần bằng hai nút − / +; số lượng nguyên liệu trên màn hình nhân theo.

- Hai nút tròn 44px, viền `outline`, nền `surface-raised`; giá trị ở giữa đậm 700, dạng "2 người".
- Chạm giới hạn (`min` mặc định 1, `max` mặc định 6) thì nút tương ứng mờ đi và không bấm được.
- Dùng ở màn Chuẩn bị nấu và Chi tiết món, đặt bên phải dòng "Khẩu phần".
- Truyền `value` và `onChange` để điều khiển, hoặc `defaultValue` để tự giữ; `unit` đổi chữ "người" thành "suất", "phần".
