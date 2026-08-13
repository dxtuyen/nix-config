# 📝 RemNote (AppImage) — Hướng dẫn chi tiết

RemNote được cài dưới dạng **AppImage** (file "ngoài Nix") để **không làm chậm rebuild** — Nix chỉ quản lý phần khung (công cụ chạy + desktop entry + script), còn file AppImage nằm ở `~/Apps/RemNote/` và được cập nhật thủ công.

## Cấu trúc

| Thành phần | Vị trí |
|---|---|
| Module Nix | `home/remnote.nix` (import trong `home/default.nix`) |
| File AppImage | `~/Apps/RemNote/RemNote.AppImage` |
| Script cập nhật | `~/.local/bin/update-remnote` |
| Desktop entry | `remnote` — Rofi/WOFI tự quét thấy |

## Lần đầu / Sang máy mới

1. **Áp dụng config** (chỉ cài khung, **không tải AppImage**):
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```
2. **Cài RemNote**:
   ```bash
   update-remnote
   ```
3. **Mở app**: tìm "RemNote" trong Rofi/WOFI.

## Cập nhật hàng ngày

Chỉ cần gõ:
```bash
update-remnote
```

Script xử lý theo thứ tự:

### Bước 1 — Ưu tiên file trong `~/Downloads/`
- Tìm file `RemNote-*.AppImage` mới nhất trong `~/Downloads/`
- Nếu có → `mv` (cắt thẳng) vào `~/Apps/RemNote/RemNote.AppImage` (file trong Downloads tự biến mất)
- Sau đó so hash 2 file:
  - Giống nhau → xóa file vừa cắt, báo "đã là phiên bản mới nhất"
  - Khác nhau → `chmod +x`, báo "Đã cập nhật RemNote"

### Bước 2 — So nội dung thật với bản đang cài (chỉ tải 1MB)
- Nếu không có file trong `~/Downloads/`, script gửi **HTTP Range request** — server chỉ gửi **1MB đầu** file (~1 giây, không tải 206MB)
- So hash 1MB này với 1MB đầu của bản đang cài:
  - **Giống nhau** → báo "RemNote đã là phiên bản mới nhất", **không tải gì thêm**
  - **Khác nhau** → có phiên bản mới, chuyển sang Bước 3

> **Vì sao so 1MB đầu mà không so ETag?** — Server RemNote dùng CDN multi-edge, ETag có thể khác nhau giữa các edge (không đáng tin). So nội dung thật (1MB đầu) chính xác 100%: 2 file AppImage khác phiên bản chắc chắn có 1MB đầu khác nhau.

### Bước 3 — Tải bản mới (có progress bar)
- Tải 206MB vào file tạm (không ghi đè trực tiếp bản đang dùng — đề phòng tải lỗi giữa chừng)
- Cài xong → `chmod +x` → báo "Đã cập nhật RemNote"

### Trường hợp mất mạng / link hỏng
- Bước 2 không lấy được 1MB → script báo:
  ```
  Không có mạng, không kiểm tra được phiên bản mới.
  Hãy tải tay file RemNote-*.AppImage về ~/Downloads rồi chạy lại lệnh này.
  ```
- **Không phá** bản đang chạy

## Khi link download bị đổi (RemNote đổi URL)

1. Tải tay file `RemNote-*.AppImage` về `~/Downloads/`
2. Gõ `update-remnote` → script tự dùng file đó, **không cần sửa config**

> Nếu muốn sửa URL mặc định trong script, mở `home/remnote.nix` và sửa dòng:
> ```nix
> url="https://backend.remnote.com/desktop/linux"
> ```

## Cập nhật config Nix

Chạy `sudo nixos-rebuild switch --flake .#laptop` — **không ảnh hưởng** AppImage đã cài (nằm ngoài Nix store).

## Tóm tắt nhanh

| Tình huống | Thao tác |
|---|---|
| Máy mới | `nixos-rebuild switch` → `update-remnote` |
| Cập nhật RemNote | `update-remnote` (tự tìm Downloads hoặc tự tải) |
| Đã mới nhất | báo ngay, **không tải 206MB** (chỉ 1MB để check) |
| Link đổi/hỏng | tải tay về `~/Downloads/` → `update-remnote` |
| Cập nhật config Nix | `nixos-rebuild switch` (không ảnh hưởng AppImage) |

## Điểm mấu chốt

- **Không làm chậm rebuild**: không tải file lớn trong build/activation
- **Bền vững**: ưu tiên file tải tay; link đổi chỉ cần tải tay, không sửa config
- **Tiết kiệm**: kiểm tra phiên bản bằng 1MB thay vì tải cả 206MB
- **Không file rác**: dùng `mv` + xóa file trùng checksum