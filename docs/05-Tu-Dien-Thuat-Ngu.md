# 05 — Từ điển thuật ngữ

## Nix / NixOS

| Thuật ngữ | Ý nghĩa |
|---|---|
| **Nix** | Trình quản lý gói + ngôn ngữ cấu hình. Repo này toàn file `.nix` |
| **nixpkgs** | Kho package chính (pinned `nixos-26.05` trong `flake.lock`) |
| **Flake** | Dự án Nix tự chứa (inputs + outputs). `flake.nix` ở gốc repo |
| **Store** | `/nix/store` — nơi chứa mọi gói/build, content-addressed |
| **Generation** | Snapshot hoàn chỉnh của hệ thống; mỗi rebuild tạo 1 bản |
| **GC** | Garbage collection — dọn các store path không dùng |
| **Module** | File `.nix` khai báo một phần của OS (`modules/nixos/*.nix`) |
| **nixos-rebuild** | Lệnh build + kích hoạt hệ thống (`switch`/`boot`/`test`) |
| **nh** | Nix helper (wrapper `nixos-rebuild`, bật trong `core.nix`) |
| **stateVersion** | `26.05` — giữ các default tương thích ngược |
| **allowUnfree** | Cho phép gói không tự do (Chrome...) |

## Swap / Hibernate

| Thuật ngữ | Ý nghĩa |
|---|---|
| **zram** | Swap nén **trong RAM** (`/dev/zram0`, 3.7G = 50% RAM, zstd, priority 5) — nhanh cho app, **không** dùng cho hibernate |
| **Swap partition** | `/dev/nvme0n1p3` (10G, priority -2), khai trong `hosts/laptop/hardware-configuration.nix` (tự sinh) — **chứa image hibernate** |
| **Hibernate** | `systemctl hibernate` — nén RAM → swap 10G, tắt nguồn; bật lại khôi phục nguyên trạng |
| **Resume** | `boot.kernelParams = ["resume=UUID=..."]` — kernel biết swap nào chứa image để dậy |

## Wayland / Desktop

| Thuật ngữ | Ý nghĩa |
|---|---|
| **Wayland** | Giao thức hiển thị hiện đại (thay X11) |
| **Sway** | Tiling window manager cho Wayland (`home/sway.nix`) |
| **Greetd / Tuigreet** | Display manager nhẹ + màn hình đăng nhập TUI |
| **Waybar / Mako** | Thanh trạng thái / daemon thông báo |
| **Alacritty** | Terminal mặc định (theme Tokyo Night) |
| **Starship** | Prompt shell tối giản (directory + git, không user@hostname) |
| **Rofi** | Launcher ứng dụng + chuyển cửa sổ |
| **PipeWire** | Máy chủ âm thanh/video (thay PulseAudio) |
| **grim / slurp** | Chụp màn hình / chọn vùng |
| **wl-clipboard** | Clipboard Wayland (`wl-copy` / `wl-paste`) |

## Home-Manager

| Thuật ngữ | Ý nghĩa |
|---|---|
| **Home Manager** | Công cụ khai báo config user (`~/.config`, `~/.local/bin`, gói user) |
| **home.packages** | Gói user trong `home/packages.nix` |
| **xdg.enable** | Bật `xdg.configFile`, `xdg.desktopEntries`, `xdg.mimeApps` |
| **desktop entry** | File `.desktop` mô tả app cho menu / file manager |
| **AppImage** | Gói app tự chứa (RemNote), chạy bằng `appimage-run` |

## Scripts (`~/.local/bin`)

Danh sách script + chức năng được giữ **một nguồn duy nhất** trong
[02 — Vận hành hằng ngày → Scripts quan trọng](02-Van-Hanh-Hang-Ngay.md)
(để không phải sửa 2 chỗ mỗi khi thêm script mới).

## Liên quan

- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — ngữ cảnh của các thuật ngữ
- [03-Cai-May-Moi](03-Cai-May-Moi.md) — thuật ngữ swap/UUID trong thực tế