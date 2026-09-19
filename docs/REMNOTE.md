# 📝 RemNote (AppImage) — Hướng dẫn chi tiết

RemNote được cài dưới dạng **AppImage** (file "ngoài Nix") để **không làm chậm rebuild** — Nix chỉ quản lý phần khung (công cụ chạy + desktop entry + script), còn file AppImage nằm ở `~/Apps/RemNote/` và được quản lý thủ công.

## Cấu trúc

| Thành phần | Vị trí |
|---|---|
| Module Nix | `home/remnote.nix` (import trong `home/default.nix`) |
| File AppImage | `~/Apps/RemNote/RemNote.AppImage` |
| Script cài đặt | `~/.local/bin/setup-remnote` |
| Desktop entry | `remnote` — Rofi/WOFI tự quét thấy |

## Máy mới / Cài mới / Cập nhật — một lệnh duy nhất

Quy trình **giống hệt nhau** cho cả 3 tình huống:

1. **Áp dụng config** (chỉ cài khung, **không tải AppImage**):
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```
2. **Tải file** `RemNote-*.AppImage` từ trang chủ RemNote về `~/Downloads/`.
3. **Chạy lệnh**:
   ```bash
   setup-remnote
   ```
4. **Mở app**: tìm "RemNote" trong Rofi/WOFI.

> **Lưu ý:** Nếu chạy `setup-remnote` mà chưa có file trong `~/Downloads/`, script sẽ báo:
> ```
> Không tìm thấy file RemNote-*.AppImage trong ~/Downloads.
> Hãy tải RemNote về ~/Downloads rồi chạy lại lệnh này.
> ```
> Chỉ cần tải file về rồi chạy lại lệnh là được.

Script làm gì (đơn giản tối đa, **KHÔNG so sánh hash**):
- Tìm file `RemNote-*.AppImage` mới nhất trong `~/Downloads/` (theo thời gian sửa).
- Không có file → báo lỗi và thoát.
- Có file → **đè thẳng** lên `~/Apps/RemNote/RemNote.AppImage` (bản cũ bị thay) + `chmod +x`.
- Dữ liệu note/kiến thức **không bị ảnh hưởng** — RemNote lưu riêng trong thư mục dữ liệu của app; thay file AppImage chỉ thay "vỏ" chương trình.

## Cài thủ công (không dùng script)

```bash
mkdir -p ~/Apps/RemNote
cp ~/Downloads/RemNote-*.AppImage ~/Apps/RemNote/RemNote.AppImage
chmod +x ~/Apps/RemNote/RemNote.AppImage
```

## Khi file bị lỗi / không chạy được

1. **Xóa file cũ**:
   ```bash
   rm ~/Apps/RemNote/RemNote.AppImage
   ```
2. **Tải lại file mới** từ trang chủ RemNote về `~/Downloads/`.
3. **Cài lại**:
   ```bash
   setup-remnote
   ```
   Hoặc cài thủ công (xem phần trên).

## Cập nhật config Nix

Chạy `sudo nixos-rebuild switch --flake .#laptop` — **không ảnh hưởng** AppImage đã cài (nằm ngoài Nix store).

## Tóm tắt nhanh

| Tình huống | Thao tác |
|---|---|
| Máy mới (lần đầu) | rebuild → tải file về `~/Downloads/` → `setup-remnote` |
| Có bản mới | tải file mới về `~/Downloads/` → `setup-remnote` (tự đè bản cũ) |
| File lỗi | xóa file cũ → tải lại → `setup-remnote` |
| Cài thủ công | `cp` + `chmod +x` (xem ở trên) |
| Cập nhật config Nix | `nixos-rebuild switch` (không ảnh hưởng AppImage) |

## Điểm mấu chốt

- **Một lệnh cho mọi tình huống**: máy mới, cài mới hay cập nhật bản mới đều là `setup-remnote`
- **Không so hash, không hỏi gì**: file trong Downloads luôn thắng — hành vi đoán được ngay
- **Không làm chậm rebuild**: không tải file lớn trong build/activation
- **Bạn tự tải**: không phụ thuộc link tải của RemNote, không lo link đổi
- **Dữ liệu tách rời vỏ app**: thay AppImage không mất gì