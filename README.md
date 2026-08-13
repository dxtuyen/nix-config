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

## Cấu trúc thư mục

```
nix-config/
├── flake.nix                      # Điểm vào chính (nixpkgs + home-manager)
├── hosts/laptop/                  # Cấu hình riêng cho máy laptop
│   └── default.nix                # Import modules + gắn home-manager
├── home/                          # Home Manager (user-level)
│   ├── default.nix                # Import tất cả module + PATH cho ~/.local/bin
│   ├── packages.nix               # Gói cài qua home.packages
│   ├── gtk.nix / sway.nix / waybar.nix / mako.nix / fcitx5.nix
│   ├── scripts.nix                # Script thủ công trong ~/.local/bin
│   └── remnote.nix                # RemNote AppImage (appimage-run + desktop entry + update-remnote)
├── modules/nixos/                 # Module NixOS (system-level) dùng chung
│   ├── core.nix / desktop.nix / development.nix / laptop.nix
├── docs/                          # Tài liệu chi tiết
│   └── REMNODE.md                 # Hướng dẫn RemNote đầy đủ
└── wallpapers/                    # Ảnh nền
```

## RemNote (AppImage)

RemNote được cài dưới dạng AppImage (file "ngoài Nix") để **không làm chậm rebuild**.

**Tóm tắt nhanh:**
| Tình huống | Thao tác |
|---|---|
| Máy mới | `nixos-rebuild switch` → `update-remnote` |
| Cập nhật RemNote | `update-remnote` (tự tìm trong Downloads hoặc tự tải) |
| Đã mới nhất | báo ngay, **không tải 206MB** (chỉ tải 1MB để kiểm tra) |
| Link đổi/hỏng | tải tay về `~/Downloads/` → `update-remnote` |

📖 **Xem hướng dẫn chi tiết tại [docs/REMNODE.md](docs/REMNODE.md)**

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
