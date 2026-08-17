# 🖥️ NixOS Laptop Config — Doxuan Tuyen

Cấu hình NixOS + Home-Manager cho laptop cá nhân, theme **Tokyo Night** đồng bộ toàn bộ (Sway, Waybar, Ghostty, GTK, Mako, Rofi).

---

## 🚀 Lệnh rebuild

```bash
cd /home/doxuantuyen/nix-config
git pull --rebase        # cập nhật code mới nhất từ GitHub
sudo nixos-rebuild switch --flake .#laptop
```

---

## 🗂️ Cấu trúc thư mục

```
nix-config/
├── flake.nix                      # Điểm vào chính (nixpkgs + home-manager)
├── hosts/laptop/                  # Cấu hình riêng cho máy laptop
│   └── default.nix                # Import modules + gắn home-manager + portal
├── home/                          # Home Manager (user-level)
│   ├── default.nix                # Import tất cả module + PATH cho ~/.local/bin
│   ├── packages.nix               # Gói cài qua home.packages
│   ├── sway.nix                   # Cấu hình Sway (window manager)
│   ├── waybar.nix                 # Thanh trạng thái Waybar
│   ├── ghostty.nix                # Terminal Ghostty (theme Tokyo Night)
│   ├── gtk.nix                    # GTK theme Tokyo Night + icon Papirus + cursor Bibata
│   ├── mako.nix                   # Trình thông báo Mako
│   ├── fcitx5.nix                 # Bộ gõ tiếng Việt Fcitx5 (Unikey)
│   ├── scripts.nix                # Script thủ công trong ~/.local/bin
│   └── remnote.nix                # RemNote AppImage (appimage-run + desktop entry + update-remnote)
├── modules/nixos/                 # Module NixOS (system-level) dùng chung
│   ├── core.nix                   # Nix settings, network, users, basic packages
│   ├── desktop.nix                # Sway, greetd, pipewire, fcitx5, fonts
│   ├── development.nix            # VS Code, Python, GCC, CMake, Podman
│   └── laptop.nix                 # Battery threshold, keyd remap, fwupd
├── docs/                          # Tài liệu chi tiết
│   └── REMNODE.md                 # Hướng dẫn RemNote đầy đủ
└── wallpapers/                    # Ảnh nền (đổi tự động theo giờ)
    ├── tokyonight-bright.jpg      # Ảnh sáng (6:00 - 17:59)
    ├── tokyonight-night.png       # Ảnh tối (18:00 - 5:59)
    └── nixos.jpg                  # Ảnh khoá màn hình (lock-screen)
```

---

## 🎨 Theme Tokyo Night

| Màu | Giá trị | Dùng cho |
|-----|---------|----------|
| Nền | `#1a1b26` | Nền cửa sổ, panel |
| Chữ | `#c0caf5` | Văn bản |
| Accent | `#7aa2f7` | Focus, border, link |
| Tím | `#bb9af7` | Split indicator |
| Không focus | `#414868` | Unfocused border |

---

## ⌨️ Phím tắt chính (Sway)

| Phím | Chức năng |
|------|-----------|
| `mod+Return` | Mở terminal (Ghostty) |
| **`mod+d`** | **Mở launcher Rofi** |
| `mod+Shift+q` | Đóng cửa sổ |
| **`mod+space`** | **Toggle floating** cửa sổ hiện tại |
| `mod+f` | Fullscreen |
| `mod+Shift+o` | Khóa màn hình |
| `mod+T` | Dịch Việt ↔ Anh |
| `mod+1..0` | Chuyển workspace |
| `mod+Shift+1..0` | Di chuyển cửa sổ sang workspace |
| `mod+r` | Mode resize (h,j,k,l) |
| `mod+b` / `mod+v` | Split ngang / dọc |
| `mod+w` / `mod+s` | Layout tabbed / stacking |
| `mod+Control+p` | Đổi power profile |

---

## 🌃 Ảnh nền tự động

- **6:00 - 17:59** → `tokyonight-bright.jpg` (sáng)
- **18:00 - 5:59** → `tokyonight-night.png` (tối)
- Cơ chế: systemd user timer chạy `cycle-wallpaper` lúc 6:00 và 18:00
- Khi reset phiên (`mod+Shift+c`) cũng tự đặt lại đúng ảnh theo giờ

---

## 📦 RemNote (AppImage)

RemNote cài dạng AppImage để không làm chậm rebuild. Tự tải file về `~/Downloads` rồi chạy `update-remnote`.

📖 Xem chi tiết tại [docs/REMNODE.md](docs/REMNODE.md)

---

## 📚 Lộ trình học nix-config

1. **Tuần 1-2:** Đọc `flake.nix` → `hosts/laptop/default.nix` → `modules/nixos/*.nix`
2. **Tuần 3-4:** `home/default.nix` → `home/sway.nix` → `home/scripts.nix`
3. **Tuần 5+:** Đào sâu các ứng dụng (waybar, ghostty, gtk, mako)
4. **Khi gặp lỗi:** `journalctl --user -u sway` → sửa → rebuild