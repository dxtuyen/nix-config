# 01 — Tổng quan hệ thống

## Máy này là gì

- **NixOS unstable** (x86_64, rolling release) chạy **Sway** (Wayland) + **Waybar** + **Mako** (thông báo) + **Foot** (terminal) + **Starship** (prompt), theme **Catppuccin Mocha** đồng bộ toàn hệ thống (GTK dùng adw-gtk3-dark trung tính).
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
| `core.nix` | Nền tảng: Nix/flake, systemd-boot, NetworkManager, user `doxuantuyen`, gói hệ thống tối thiểu, ssh-agent (giữ passphrase SSH key) |
| `desktop.nix` | Sway + greetd, PipeWire, XDG portal, Fcitx5 + Bamboo, fonts, power-profiles-daemon, bluetooth, Thunar + `tumbler` (thumbnail), **timer dọn thùng rác 03:00 (giữ 30 ngày)**, symlink `/usr/share/hyphen` cho WebKit |
| `development.nix` | VS Code, Python, GCC, CMake, gdb, podman, distrobox, nix-ld |
| `laptop.nix` | **Hibernate** (`resume=/dev/disk/by-label/swap`), zram 50% RAM, keyd, battery threshold 85–90%, fwupd, logind (đóng nắp → suspend) — **swap tự nhận diện theo nhãn `swap`** |
| `system-tweaks.nix` | earlyoom (chống treo RAM), fstrim hàng tuần |

## Các phần trong `home/`

| Thư mục/file | Nội dung |
|---|---|
| `default.nix` | Thiết lập tài khoản Home Manager, shell và imports ba nhóm cấu hình. |
| `config/` | Gói người dùng, Git, Nixvim, Sway, Waybar, terminal, theme, MIME và bộ gõ. |
| `apps/` | Tích hợp ứng dụng có cấu hình riêng: Pomodoro, RemNote, Sioyek, Thunar, wallpaper/awww và Yazi. |
| `script/` | Mỗi lệnh `~/.local/bin` có một file riêng; `default.nix` liệt kê các script. `quick-lang.nix` chứa model, prompt và Gemini API. |

Neovim được cấu hình bằng Nixvim tại `home/config/nixvim.nix`; phím leader là Space.
`fzf` được cài độc lập qua `programs.fzf` trong `home/default.nix`, dùng trực tiếp
trong terminal cùng Bash integration; cấu hình này không phụ thuộc Yazi.

## Dòng chảy khởi động

1. Boot → **systemd-boot** chọn generation.
2. **greetd** (tuigreet) hiện màn hình đăng nhập → chạy Sway.
3. Sway kích hoạt `sway-session.target`: Waybar, Fcitx5, wlsunset, awww-daemon + `wallpaper-set` (tự đổi ảnh random mỗi lần vào Sway)… (timer đổi nền 30 phút **đã TẮT**, xem [02](02-Van-Hanh-Hang-Ngay.md#ảnh-nền-wallpaper)). Wi-Fi và Bluetooth mở từ Utilities (`$mod+Shift+o`); Pomodoro dùng `$mod+p`.
4. **swayidle** lo chuỗi khóa màn hình → tắt màn → suspend (xem [02-Van-Hanh-Hang-Ngay](02-Van-Hanh-Hang-Ngay.md)).

## Config vs Dữ liệu (quan trọng nhất)

- **Config** (`.nix`, theme, phím tắt, danh sách gói) → nằm trong Nix, **tái tạo được** từ repo.
- **Dữ liệu** (RemNote AppImage, Gemini API key, từ điển StarDict, tài liệu, ảnh chụp màn hình...) → **nằm ngoài Nix**, máy mới không tự có. ⇒ **Phải backup** — xem [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md).

## Liên quan

- [02-Van-Hanh-Hang-Ngay](02-Van-Hanh-Hang-Ngay.md) — cách áp dụng thay đổi mỗi ngày
- [03-Cai-May-Moi](03-Cai-May-Moi.md) — cài từ đầu lên máy mới
- [05-Tu-Dien-Thuat-Ngu](05-Tu-Dien-Thuat-Ngu.md) — tra thuật ngữ
