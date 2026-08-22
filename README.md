# 🖥️ NixOS Config — Doxuan Tuyen

Cấu hình **NixOS + Home-Manager** cho laptop cá nhân, chạy **Sway** (Wayland), theme **Tokyo Night** đồng bộ toàn bộ.

| | |
|---|---|
| 🌐 Hệ thống | NixOS 26.05 (x86_64-linux) |
| 🪟 Desktop | Sway + Waybar + Mako (notification) |
| 🎨 Terminal | Foot (thay Ghostty — nhẹ hơn, mượt hơn) |
| ⌨️ Bộ gõ | Fcitx5 + Unikey |
| 🎨 Bộ bìa | Tokyo Night (`#1a1b26`) |

---

## 🚀 Rebuild & Cập nhật

Luôn thực hiện từ thư mục repo:

```bash
cd nix-config
git pull --rebase        # lấy code mới nhất
nix fmt                   # format toàn bộ *.nix (nixfmt)
sudo nixos-rebuild switch --flake .#laptop
```

> Vì Home-Manager được gắn vào NixOS qua `home-manager.nixosModules`, lệnh `nixos-rebuild switch` duy nhất sẽ cập nhật **cả hệ điều hành lẫn home-manager** — không cần chạy lệnh switch riêng.

Các lệnh bảo trì thường dùng:

```bash
nix flake update                   # cập nhật flake.lock
nix-collect-garbage -d             # dọn bộ nhớ cũ
journalctl -b -u sway              # đọc log sway phiên hiện tại
journalctl --user -u sway          # log sway nếu cần
```

---

## 🗂️ Cấu trúc thư mục

```
nix-config/
├── flake.nix                    # Điểm vào: nixpkgs + home-manager, đích build "laptop"
├── hosts/laptop/                # Cấu hình riêng cho máy laptop
│   ├── default.nix              # Import modules + gắn home-manager
│   └── hardware-configuration.nix  # Tự sinh khi cài máy
├── home/                        # Home Manager (user-level) — import hết từ default.nix
│   ├── default.nix              # Entry point: imports + chia PATH ~/.local/bin
│   ├── packages.nix             # Gói cài qua home.packages
│   ├── sway.nix                 # Cấu hình Sway (window manager, phím tắt, idle/lock/sleep)
│   ├── waybar.nix               # Thanh trạng thái (workspaces, pomo, battery, cpu...)
│   ├── foot.nix                 # Terminal foot (theme Tokyo Night)
│   ├── gtk.nix                  # GTK theme Tokyonight-Dark + icon Papirus-Dark + cursor Bibata
│   ├── mako.nix                 # Trình thông báo Mako (custom timeout từng app)
│   ├── fcitx5.nix               # Bộ gõ tiếng Việt Fcitx5 (Unikey)
│   ├── scripts.nix              # Các script thủ công trong ~/.local/bin
│   ├── pomodoro.nix             # Pomodoro timer + menu rải rác (rẻ, phát âm)
│   ├── thunar.nix               # Đăng ký Foot làm terminal mặc định cho Thunar
│   └── remnote.nix              # RemNote AppImage (appimage-run + desktop entry + update-remnote)
├── modules/nixos/               # Module NixOS (system-level) dùng chung
│   ├── core.nix                 # Flakes, GC weekly, network, user, packages nền
│   ├── desktop.nix              # Sway, greetd (tuigreet), pipewire, portal, fcitx5, fonts
│   ├── development.nix          # VS Code, Python, GCC, CMake, gdb, distrobox, podman
│   ├── laptop.nix               # Battery threshold 85-90%, keyd remap, fwupd, zram
│   └── system-tweaks.nix        # earlyoom (tự sát mất hog), fstrim weekly, nix-ld
├── docs/
│   ├── nixmap/                  # Tài liệu học tập về NixOS / configuraion này
│   └── REMNODE.md               # Hướng dẫn RemNote AppImage đầy đủ
└── wallpapers/                  # Ảnh nền (đổi tự động theo giờ)
    ├── tokyonight-bright.jpg    # Sáng (06:00 – 17:59)
    ├── tokyonight-night.png     # Tối  (18:00 – 05:59)
    └── nixos.jpg                # Ảnh khóa màn hình (swaylock)
```

---

## 🔐 Khóa màn hình • Idle • Sleep

Chuỗi tự động hóa (theo đúng sway wiki) do `swayidle` quản lý:

| Sau | Hành động | Ghi chú |
|-----|-----------|---------|
| **300s** (5 phút) | Khóa màn hình (`lock-screen`) | Script khóa sẽ tắt màn sau 10s nữa nếu không hoạt động |
| **900s** (15 phút) | **Sleep (suspend)** | Chỉ sau khi đã khóa — an toàn |
| **before-sleep** | Luôn khóa lại trước khi ngủ | Chống người khác dùng khi mở máy |

**Script `lock-screen`** (trong `~/.local/bin`):
- Idempotent: đã khóa → thoát (tránh phải mở khóa 2 lần)
- Khi khóa sẽ BẮT đầu một `swayidle` phụ: sau 10s không thao tác → tắt màn (`power off`); có thao tác → bật màn ngay nhưng **vẫn khóa**
- Khi mở khóa thành công, `trap EXIT` dọn dẹp tài nguyên

---

## ⌨️ Phím tắt chính (Sway)

| Phím | Chức năng |
|------|-----------|
| `Mod+Return` | Mở terminal (foot) |
| `Mod+d` | Launcher Rofi (drun) |
| `Mod+Tab` | Chuyển cửa sổ (Rofi window) |
| `Mod+Shift+q` | Đóng cửa sổ |
| `Mod+Shift+c` | Reset phiên (refresh-session) |
| `Mod+Shift+e` | Thoát Sway (swaynag xác nhận) |
| `Mod+Shift+n` | Toggle wlsunset (Auto → Vàng 4000K → Trắng 6500K) |
| `Mod+p` | Pomodoro menu |
| `Mod+Shift+p` | Menu nguồn (poweroff/reboot/suspend/lock/profile…) |
| `Mod+Shift+s` | Mở nhanh ứng học (RemNote + Calibre) |
| `Mod+t` | Dịch Việt → Anh (quick-lang) |
| `Mod+Shift+t` | Dịch Anh → Việt (quick-lang) |
| `Mod+Ctrl+t` | Toggle touchpad |
| `Mod+Print` | Menu screenshot |
| `Print` | Screenshot vùng chọn → clipboard |
| `Mod1+Print` | Screenshot toàn màn → clipboard |
| `Shift+Print` | Screenshot vùng chọn → lưu file |
| `Ctrl+Print` | Screenshot toàn màn → lưu file |
| `Mod+f` | Fullscreen |
| `Mod+space` | Focus mode toggle (duyệt cửa sổ) |
| `Mod+Shift+space` | Floating toggle |
| `Mod+b` / `Mod+v` | Chia ngang / chia dọc |
| `Mod+w` / `Mod+s` | Layout tabbed / stacking |
| `Mod+e` | Chuyển layout (split/tab/stack) |
| `Mod+r` | Mode resize (dùng `h j k l`) |
| `Mod+{1..9,0}` | Chuyển workspace (1-4 có tên: study, AI, code, others) |
| `Mod+Shift+{1..9,0}` | Di chuyển container tới workspace |
| `Mod+u` / `Mod+i` | Workspace trước / sau |
| `Mod+Shift+minus` / `Mod+minus` | Move view ra scratchpad / hiện scratchpad |
| `XF86AudioRaiseVolume` | Tăng âm lượng (kèm OSD) |
| `XF86AudioLowerVolume` | Giảm âm lượng |
| `XF86AudioMute` / `XF86MicMute` | Tắt tiếng / tắt mic |
| `XF86MonBrightnessUp/Down` | Tăng/giảm độ sáng |

---

## 🎨 Bộ Tokyo Night

| Màu | Giá trị | Dùng cho |
|-----|---------|----------|
| Nền | `#1a1b26` | Nền cửa sổ, panel |
| Chữ | `#c0caf5` | Văn bản |
| Accent | `#7aa2f7` | Focus, border, link |
| Tím | `#bb9af7` | Split indicator |
| Không focus | `#414868` | Unfocused border |

Bộ màu đồng nhất: Sway (borders, modes), Foot (palette 16), Waybar (modules CSS), Mako (notify), GTK (theme Tokyonight-Dark), cursor Bibata.

---

## 🌃 Ảnh nền tự động

- **06:00 – 17:59** → `tokyonight-bright.jpg`
- Đổi lúc **18:00** → `tokyonight-night.png`
- Cơ chế: systemd **user timer** (`cycle-wallpaper.timer`) chạy 2 lần/ngày + kèm script khi reset phiên

---

## 💡 Tính năng laptop

| Tính năng | Mô tả |
|-----------|--------|
| **ZRAM** | Swap nén zstd 50% RAM — nhanh hơn SSD swap, giảm mòn ổ |
| **Battery threshold** | Sạc giới hạn 85–90% (systemd service lúc boot) |
| **keyd** | Caps Lock = `Ctrl` (giữ) / `Esc` (ghím) — phím `Tab` nhấn giữ = mode navigation `h j k l u i o p` |
| **Power profiles** | `power-profiles-daemon`: battery saver / balanced / performance (Menu `Mod+Shift+p`) |
| **earlyoom** | Giết tiến trình làm cạn RAM (5%) trước khi treo desktop |
| **fstrim** | Trim SSD mỗi tuần |
| **nix-ld** | Chạy binary portable (VS Code server, JetBrains...) |
| **fwupd** | Cập nhật firmware |

---

## 📦 RemNote (AppImage)

RemNote cài bằng AppImage để không làm chậm rebuild. Tự tải về `~/Downloads` rồi chạy `update-remnote`.

📖 Xem chi tiết: [docs/REMNODE.md](docs/REMNODE.md) và [docs/nixmap/](docs/nixmap/README.md)

---

## ⚠️ Xử lý sự cố thường gáp

| Triệu chứng | Kiểm tra |
|-------------|----------|
| Sway không khởi động | `journalctl -b -u greetd` |
| Âm thanh lỗi | `systemctl status pipewire` → restart: `systemctl --user restart wireplumber` |
| Bộ gõ khớ cào | `fcitx5-diagnose` |
| Wallpaper sai giờ | `systemctl --user status cycle-wallpaper.timer` |
| WLSunset bị lệch khi toggle | Toggle mới query thực tế từ `/proc` — nên đã khỏi; nếu trạng thái đen → `pkill -x wlsunset; wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &` |

---

## 📚 Lộ trình học nix-config

1. **Tuần 1-2:** `flake.nix` → `hosts/laptop/default.nix` → `modules/nixos/*.nix`
2. **Tuần 3-4:** `home/default.nix` → `home/sway.nix` → `home/scripts.nix` → `home/pomodoro.nix`
3. **Tuần 5+:** Đào sâu từng ứng dụng (waybar, foot, gtk, mako, fcitx5, remnote, thunar)
4. **Kho gặp lỗi:** `journalctl --user -u sway` → sửa file → `nixos-rebuild switch`