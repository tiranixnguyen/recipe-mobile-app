# Button

Nút bấm cho hành động; `primary` (nền chili) chỉ dùng **một lần mỗi màn hình**, cho việc chính của màn đó.

- `variant`: `primary` (mặc định) · `secondary` (viền `outline`) · `ghost` (chữ `chili-deep`, cho hành động phụ như "Bỏ qua") · `danger` (nền `danger`, chỉ cho hành động không hoàn tác được như "Xoá hết"; để `disabled` cho tới khi người dùng xác nhận).
- Cao tối thiểu 48px (vùng chạm), bo `radius-md`, chữ 15/600. `icon` nhận tên trong bộ Icon.
- `size="lg"`: cao 56px, chữ 17/24. Dùng cho nút điều hướng ở chế độ nấu ("Bước trước", "Bước tiếp", "Bắt đầu nấu"), khi tay bận và điện thoại dựng cạnh bếp.
- Nhãn bắt đầu bằng động từ, viết hoa chữ đầu: "Thêm vào danh sách đi chợ", không "THÊM".
- `block` cho nút chiếm hết chiều ngang ở cuối màn hình.
