# StepTimer

Hẹn giờ cho một bước nấu: lúc đầu là nút "Hẹn 3 phút", bấm vào thành thanh đếm ngược.

- Chưa chạy: Button `secondary` với icon `timer`, nhãn "Hẹn" + thời lượng ("Hẹn 3 phút", "Hẹn 45 giây").
- Đang chạy: thanh nền `ink`, chữ trắng; dòng nhỏ là tên việc (`label`), số lớn 28/34 700 dạng `02:45`; nút "Dừng" viền trắng.
- Hết giờ: thanh chuyển nền `chili`, hiện "Hết giờ · …" và "Xong!", nút đổi thành "Tắt". Trên app thật, kèm rung và thông báo khi app chạy nền.
- Đặt ngay trên hai nút điều hướng của màn nấu, lề `space-4`; thanh vẫn hiện khi người dùng chuyển sang bước khác.
- `onStatusChange(status)` báo khi timer chuyển giữa `idle` / `running` / `done`. Màn chủ dùng nó để giữ thanh đang chạy luôn hiện khi người dùng sang bước khác: giữ mỗi bước một StepTimer, ẩn cái `idle` không thuộc bước đang xem, không bao giờ ẩn cái `running` hay `done`.
- Người dùng truyền `seconds` và `label`; `onDone` để rung, báo. Trong Flutter, thời gian chạy theo giờ hệ thống, không theo số tick.
