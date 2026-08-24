# 01 — Tổng quan hệ thống

## Máy này là gì

- **NixOS 26.05** (x86_64) chạy **Sway** (Wayland) + **Waybar** + **Mako** (thông báo) + **Foot** (terminal), theme **Tokyo Night** đồng bộ toàn hệ thống.
- Toàn bộ cấu hình nằm trong repo `nix-config` (được version bằng git) — không cài "theo kiểu Ubuntu" mà **khai báo rồi build** ra hệ thống.

## Hai tầng cấu hình

| Tầng | Thư mục | Quản lý bởi | Gồm |
|---|---|---|---|
| Hệ điều hành | `modules/nixos/` | NixOS (cần root) | boot, mạng, Sway/greetd, âm thanh, bộ gõ, user, swap + hibernate |
| Người dùng | `home/` | Home-Manager | config Sway, Waybar, Foot, script cá nhân, gói user |

- Entry point: `flake.nix` → `hosts/laptop/default.nix` → import các module NixOS + gắn home-manager cho user `doxuantuyen`.
- Một lệnh `sudo nixos-rebuild switch --flake .#laptop` cập nhật **cả hai tầng**.

## Các module NixOS (`modules/nixos/`)

| Module | Trách nhiệm |
|---|---|
| `core.nix` | Nền tảng: Nix/flake, systemd-boot, NetworkManager, user `doxuantuyen`, gói hệ thống tối thiểu |
| `desktop.nix` | Sway + greetd (tuigreet), PipeWire, XDG portal, Fcitx5 + Unikey, fonts, power-profiles-daemon, bluetooth |
| `development.nix` | VS Code, Python, GCC, CMake, gdb, podman, distrobox, nix-ld |
| `laptop.nix` | **Hibernate** (`resume=UUID=`), zram 50% RAM, keyd, battery threshold 85–90%, fwupd, logind (đóng nắp → suspend) — **swap khai trong `hosts/laptop/hardware-configuration.nix`** (tự sinh) |
| `system-tweaks.nix` | earlyoom (chống treo RAM), fstrim hàng tuần |

## Các file trong `home/`

| File | Nội dung |
|---|---|
| `default.nix` | Entry point: import tất cả, bật `xdg`, PATH `~/.local/bin` |
| `packages.nix` | Gói user: rofi, grim, slurp, swaylock, swayidle, google-chrome, obsidian, anki, calibre, sioyek, ticktick... |
| `sway.nix` | Cửa sổ, layout, idle/lock/sleep (swayidle), phím tắt (xem [02-Van-Hanh-Hang-Ngay](02-Van-Hanh-Hang-Ngay.md)) |
| `waybar.nix` / `foot.nix` / `gtk.nix` / `mako.nix` | Thanh trạng thái / terminal / theme / thông báo |
| `fcitx5.nix` | Bộ gõ tiếng Việt |
| `scripts.nix` | Script `~/.local/bin`: lock-screen, power-menu, quick-lang, screenshot-menu, cycle-wallpaper... |
| `pomodoro.nix` | Pomodoro timer + menu |
| `remnote.nix` | RemNote AppImage (khung cài + script `update-remnote`) |
| `thunar.nix` | File manager + mở terminal bằng Foot |

## Dòng chảy khởi động

1. Boot → **systemd-boot** chọn generation.
2. **greetd** (tuigreet) hiện màn hình đăng nhập → chạy Sway.
3. Sway kích hoạt `sway-session.target`: Waybar, Fcitx5, nm-applet, wlsunset, cycle-wallpaper...
4. **swayidle** lo chuỗi khóa màn hình → tắt màn → suspend (xem [02-Van-Hanh-Hang-Ngay](02-Van-Hanh-Hang-Ngay.md)).

## Config vs Dữ liệu (quan trọng nhất)

- **Config** (`.nix`, theme, phím tắt, danh sách gói) → nằm trong Nix, **tái tạo được** từ repo.
- **Dữ liệu** (RemNote AppImage, Gemini API key, từ điển StarDict, tài liệu, ảnh chụp màn hình...) → **nằm ngoài Nix**, máy mới không tự có. ⇒ **Phải backup** — xem [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md).

## Liên quan

- [02-Van-Hanh-Hang-Ngay](02-Van-Hanh-Hang-Ngay.md) — cách áp dụng thay đổi mỗi ngày
- [03-Cai-May-Moi](03-Cai-May-Moi.md) — cài từ đầu lên máy mới
- [05-Tu-Dien-Thuat-Ngu](05-Tu-Dien-Thuat-Ngu.md) — tra thuật ngữ