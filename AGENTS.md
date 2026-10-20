# AGENTS.md

App Flutter công thức nấu ăn cho sinh viên khu Hoà Lạc. Setup và lệnh: xem `README.md` (luôn dùng `fvm flutter …`).

## Thiết kế

Trước khi dựng hay sửa UI, đọc [`docs/design/README.md`](docs/design/README.md).

- Màu, chữ, spacing, radius lấy từ `docs/design/design-system/tokens.json` (có theme `light` và `dark`); không mã màu cứng trong widget.
- Quy tắc component: `docs/design/design-system/components/<Tên>/README.md`.
- Layout, chữ hiển thị và điều hướng của từng màn: `docs/design/prototype/<Màn>.dc.html`.
- Giọng văn UI: tiếng Việt có dấu, xưng "bạn", không emoji, không hiển thị giá tiền.
- `docs/design/` là bản sao từ artifact trên claude.ai; đừng sửa tay, xem mục *Sync lại* trong README đó.
