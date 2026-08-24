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
2. **Tải file** `RemNote-*.AppImage` từ trang chủ RemNote về `~/Downloads/`.
3. **Cài RemNote**:
   ```bash
   update-remnote
   ```
4. **Mở app**: tìm "RemNote" trong Rofi/WOFI.

> **Lưu ý:** Nếu chạy `update-remnote` mà chưa có file trong `~/Downloads/`, script sẽ báo:
> ```
> Không tìm thấy file RemNote-*.AppImage trong ~/Downloads.
> Hãy tải RemNote về ~/Downloads rồi chạy lại lệnh này.
> ```
> Chỉ cần tải file về rồi chạy lại lệnh là được.

## Cập nhật hàng ngày

1. **Tải file mới** `RemNote-*.AppImage` từ trang chủ RemNote về `~/Downloads/`.
2. **Chạy lệnh**:
   ```bash
   update-remnote
   ```

Script xử lý:
- Tìm file `RemNote-*.AppImage` mới nhất trong `~/Downloads/` (theo thời gian sửa).
- **Không có file** → báo "Không tìm thấy... Hãy tải về..." và thoát.
- **Có file** → so sánh hash (sha256sum) với bản đang cài:
  - **Giống nhau** → xóa file mới, báo "RemNote đã là phiên bản mới nhất, không cần cập nhật."
  - **Khác nhau** → cài bản mới (mv + chmod +x), báo "Đã cập nhật RemNote."

## Cài thủ công (không dùng script)

Nếu muốn tự cài file AppImage mà không dùng script:

```bash
mkdir -p ~/Apps/RemNote
cp ~/Downloads/RemNote-*.AppImage ~/Apps/RemNote/RemNote.AppImage
chmod +x ~/Apps/RemNote/RemNote.AppImage
```

Sau đó mở app bằng cách tìm "RemNote" trong Rofi/WOFI.

## Khi file bị lỗi / không chạy được

1. **Xóa file cũ**:
   ```bash
   rm ~/Apps/RemNote/RemNote.AppImage
   ```
2. **Tải lại file mới** từ trang chủ RemNote về `~/Downloads/`.
3. **Cài lại**:
   ```bash
   update-remnote
   ```
   Hoặc cài thủ công (xem phần trên).

## Cập nhật config Nix

Chạy `sudo nixos-rebuild switch --flake .#laptop` — **không ảnh hưởng** AppImage đã cài (nằm ngoài Nix store).

## Tóm tắt nhanh

| Tình huống | Thao tác |
|---|---|
| Máy mới | `nixos-rebuild switch` → tải file về `~/Downloads/` → `update-remnote` |
| Cập nhật RemNote | tải file mới về `~/Downloads/` → `update-remnote` |
| Đã mới nhất | báo ngay, không cần làm gì |
| Cài thủ công | `cp` + `chmod +x` (xem ở trên) |
| File lỗi | xóa file cũ → tải lại → `update-remnote` |
| Cập nhật config Nix | `nixos-rebuild switch` (không ảnh hưởng AppImage) |

## Điểm mấu chốt

- **Không làm chậm rebuild**: không tải file lớn trong build/activation
- **Đơn giản**: script chỉ lo tìm file + so sánh hash + cài đặt
- **Bạn tự tải**: không phụ thuộc link tải của RemNote, không lo link đổi
- **Không file rác**: dùng `mv` + xóa file trùng checksum