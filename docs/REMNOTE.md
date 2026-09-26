# 📝 RemNote (AppImage) — Hướng dẫn chi tiết

RemNote được cài dưới dạng **AppImage** (file "ngoài Nix") để **không làm chậm rebuild** — Nix chỉ quản lý phần khung (công cụ chạy + desktop entry + script), còn file AppImage nằm ở `~/Apps/RemNote/` và được quản lý thủ công.

## Cấu trúc

| Thành phần | Vị trí |
|---|---|
| Module Nix | `home/remnote.nix` (import trong `home/default.nix`) |
| File AppImage | `~/Apps/RemNote/RemNote.AppImage` |
| Script cài đặt | `~/.local/bin/setup-remnote` |
| Icon | `~/.local/share/icons/hicolor/512x512/apps/remnote.png` (trích từ AppImage) |
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
- **Trích icon** từ AppImage ra `~/.local/share/icons/hicolor/512x512/apps/remnote.png` (xem [Icon trong Rofi](#icon-trong-rofi)).
- Dữ liệu note/kiến thức **không bị ảnh hưởng** — RemNote lưu riêng trong thư mục dữ liệu của app; thay file AppImage chỉ thay "vỏ" chương trình.

## Icon trong Rofi

Bản `nixos-rebuild` **chỉ tạo desktop entry, không tạo file icon** — icon nằm bên trong file AppImage
(ngoài Nix) nên phải trích ra. Vì vậy sau `rebuild` phải chạy `setup-remnote` một lần thì icon mới có.

Vài điểm dễ sai đã được xử lý sẵn trong `home/remnote.nix`:

| Vấn đề | Cách sửa trong repo |
|---|---|
| Desktop entry không có dòng `Icon=` → Rofi hiện mục **không icon** | Khai báo `icon = "<đường dẫn tuyệt đối tới file .png>"` |
| AppImage đặt icon ở thư mục size **không chuẩn** `hicolor/0x0` → GTK **không đọc** size này, copy nguyên thư mục cũng vẫn mất icon | `setup-remnote` copy file ra `hicolor/**512x512**/apps/remnote.png` (size GTK thật sự đọc) |
| `Exec=appimage-run ...` (tên trần) → Rofi **loại bỏ entry** khi binary không có trong `PATH` của session | Trỏ tuyệt đối: `${pkgs.appimage-run}/bin/appimage-run` |
| Trỏ icon **bằng tên** (`Icon=remnote`) → phụ thuộc icon theme đang dùng (`Papirus-Dark`) và icon cache của GTK | Trỏ **đường dẫn tuyệt đối** tới file PNG — không phụ thuộc theme, không phụ thuộc cache |

Lưu ý khi debug:

- `~/.cache/rofi3.druncache` chỉ là bộ đếm **số lần dùng**, KHÔNG phải cache danh sách app → sửa desktop entry xong mở lại Rofi là thấy ngay, không cần xoá cache.
- Desktop entry đang dùng: `/etc/profiles/per-user/doxuantuyen/share/applications/remnote.desktop`.
  Kiểm tra nhanh:
  ```bash
  grep Icon= /etc/profiles/per-user/doxuantuyen/share/applications/remnote.desktop
  ```
- Nếu `setup-remnote` báo `Cảnh báo: không tìm thấy icon ...` ⇒ AppImage mới đã đổi cấu trúc bên trong. App vẫn chạy bình thường, chỉ mất icon; cần sửa biến `icon_in_appimage` trong `home/remnote.nix` cho khớp.

## Cài thủ công (không dùng script)

```bash
mkdir -p ~/Apps/RemNote
cp ~/Downloads/RemNote-*.AppImage ~/Apps/RemNote/RemNote.AppImage
chmod +x ~/Apps/RemNote/RemNote.AppImage
```

⚠️ Cách này **không có icon** trong Rofi — phải trích icon thủ công:

```bash
mkdir -p ~/.local/share/icons/hicolor/512x512/apps
(cd "$(mktemp -d)" && ~/Apps/RemNote/RemNote.AppImage \
   --appimage-extract 'usr/share/icons/hicolor/0x0/apps/remnote.png')
cp squashfs-root/usr/share/icons/hicolor/0x0/apps/remnote.png \
   ~/.local/share/icons/hicolor/512x512/apps/remnote.png
rm -rf squashfs-root
```

Nên cứ dùng `setup-remnote` — nó làm cả hai việc trong một lệnh.

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
| Máy mới (lần đầu) | rebuild → tải file về `~/Downloads/` → `setup-remnote` (file + icon) |
| Có bản mới | tải file mới về `~/Downloads/` → `setup-remnote` (tự đè bản cũ + làm mới icon) |
| File lỗi | xóa file cũ → tải lại → `setup-remnote` |
| Cài thủ công | `cp` + `chmod +x` (xem ở trên) |
| Cập nhật config Nix | `nixos-rebuild switch` (không ảnh hưởng AppImage) |

## Điểm mấu chốt

- **Một lệnh cho mọi tình huống**: máy mới, cài mới hay cập nhật bản mới đều là `setup-remnote`
- **Không so hash, không hỏi gì**: file trong Downloads luôn thắng — hành vi đoán được ngay
- **Không làm chậm rebuild**: không tải file lớn trong build/activation
- **Bạn tự tải**: không phụ thuộc link tải của RemNote, không lo link đổi
- **Dữ liệu tách rời vỏ app**: thay AppImage không mất gì