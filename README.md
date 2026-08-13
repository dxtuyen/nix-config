# 📘 Chuyển sang máy mới — Hướng dẫn nhanh

## Khi nào cần

- Cài lại / nâng cấp hệ thống
- Hiểu vì sao máy chạy / không chạy
- Đồng bộ cấu hình sang máy khác

---

## 1. Chuẩn bị

Trước khi rebuild, **commit (lưu) lại toàn bộ thay đổi** (Git là bắt buộc với Nix):

```bash
sudo nixos-rebuild switch --flake .#laptop
```

Nếu chưa có Git:

```bash
git init
git add .
git commit -m "Cấu hình laptop"
git push origin main   # sao lưu lên GitHub/GitLab riêng
```

---

## 2. Lệnh rebuild

```bash
cd /home/doxuantuyen/nix-config
git pull --rebase        # cập nhật code mới nhất từ GitHub
sudo nixos-rebuild switch --flake .#laptop
```

---

## 3. Chuyển sang máy mới

1. **Cài Git + clone repo** trên máy mới:
   ```bash
   git clone <url-repo-của-bạn>
   cd nix-config
   ```

2. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

---

## Lộ trình học hiểu `nix-config` từ đầu

Đọc tuần tự, mỗi ngày một phần:

### Tuần 1-2: Nền tảng
- Đọc `flake.nix` → `inputs`, `outputs` → module `./hosts/laptop/default.nix`
- Xem `modules/nixos/*.nix` — module dùng chung.

### Tuần 3-4: Cấu hình chính
- `hosts/laptop/default.nix` → nơi định nghĩa hostname, users, waybar...
- Bắt đầu xem phần `imports` → `home-manager.users...`

### Tuần 5-7: Home-manager & Ứng dụng
- `home/packages.nix` → `home/sway.nix` → `home/waybar.nix`
- Đọc kỹ `home/default.nix` phần **style** và phần **scripts.nix**

### Khi Sway gặp lỗi
- Xem log: `journalctl --user -u sway`
- Sửa file `home/sway.nix` → rebuild.

---

## Mẹo đọc / tìm kiếm

- **Tìm nhanh config:**
  ```bash
  grep -n "battery" home/default.nix
  ```
- **Chạy thử an toàn:**
  ```bash
  nix eval '.#nixosConfigurations.laptop...'
  ```
- **Rebuild thành công:**
  ```bash
  sudo nixos-rebuild boot --flake .#laptop
  ```

---

## File thiết yếu

- `hosts/laptop/default.nix`
- `home/default.nix`
- `modules/nixos/*.nix`
- `wallpapers/nixos.jpg` — ảnh nền màn hình

---

## RemNote (AppImage) — Hướng dẫn chi tiết

RemNote được cài dưới dạng **AppImage** (file "ngoài Nix") để **không làm chậm rebuild** — Nix chỉ quản lý phần khung (công cụ chạy + desktop entry + script), còn file AppImage nằm ở `~/Apps/RemNote/` và được cập nhật thủ công.

### Cấu trúc
- **Module**: `home/remnote.nix` (đã import trong `home/default.nix`)
- **Vị trí AppImage**: `~/Apps/RemNote/RemNote.AppImage`
- **Script cập nhật**: `~/.local/bin/update-remnote`
- **Desktop entry**: `remnote` — Rofi/WOFI tự quét thấy

### Lần đầu / Sang máy mới
1. **Áp dụng config** (chỉ cài khung, không tải AppImage):
   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```
2. **Cài RemNote**:
   ```bash
   update-remnote
   ```
   Script tự xử lý:
   - Có file `RemNote-*.AppImage` trong `~/Downloads/` → dùng file đó
   - Không có → tự tải từ URL về `~/Apps/RemNote/RemNote.AppImage`
3. **Mở app**: tìm "RemNote" trong Rofi/WOFI.

### Cập nhật RemNote hàng ngày
Chỉ cần gõ:
```bash
update-remnote
```
Script xử lý theo thứ tự:
1. **Có file mới trong `~/Downloads/`** → `mv` (cắt thẳng) file mới nhất vào `~/Apps/RemNote/RemNote.AppImage` (file trong Downloads tự biến mất)
2. **Không có file** → tự tải từ URL
3. **So checksum** với bản hiện tại:
   - Giống nhau → xóa file mới, báo "RemNote đã là phiên bản mới nhất"
   - Khác nhau → giữ bản mới, `chmod +x`, báo "Đã cập nhật RemNote"
4. **Mất mạng / link hỏng** → báo lỗi + hướng dẫn tải tay, **không phá** bản đang chạy

### Khi link download bị đổi (RemNote đổi URL)
1. Tải tay file `RemNote-*.AppImage` về `~/Downloads/`
2. Gõ `update-remnote` → script tự dùng file đó, **không cần sửa config**

### Cập nhật config Nix
Chạy `sudo nixos-rebuild switch --flake .#laptop` — **không ảnh hưởng** AppImage đã cài (nằm ngoài Nix store).

### Tóm tắt
| Tình huống | Thao tác |
|---|---|
| Máy mới | `nixos-rebuild switch` → `update-remnote` |
| Cập nhật RemNote | `update-remnote` (tự tìm trong Downloads hoặc tự tải) |
| Link đổi/hỏng | tải tay về `~/Downloads/` → `update-remnote` |
| Cập nhật config Nix | `nixos-rebuild switch` (không ảnh hưởng AppImage) |

### Điểm mấu chốt
- **Không làm chậm rebuild**: không tải file lớn trong build/activation
- **Bền vững**: ưu tiên file tải tay; link đổi chỉ cần tải tay, không sửa config
- **Không file rác**: dùng `mv` + xóa file trùng checksum

---

## Ảnh nền & `result` — Giải thích

### Ảnh nền
- File ảnh nền đặt tại `wallpapers/nixos.jpg`
- Cấu hình dùng ảnh trong `home/sway.nix`:
  ```nix
  output * bg ${./../wallpapers/nixos.jpg} fill
  ```
- Đổi ảnh nền = thay file trong `wallpapers/`, không cần sửa cấu hình.

### Symlink `result`
- `result` là **symlink tạm** do `nix build` tạo ra — trỏ đến cấu hình vừa build trong `/nix/store`
- **Không phải file của dự án**, không cần commit, có thể xóa an toàn
- Đã thêm vào `.gitignore` nên không xuất hiện trong Git nữa
- Nếu thấy nó xuất hiện, nguyên nhân là một lệnh `nix build` vừa chạy trong thư mục này.
