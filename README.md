# 🖥️ NixOS Config — Doxuan Tuyen

Cấu hình **NixOS + Home-Manager** cho laptop cá nhân, chạy **Sway** (Wayland), theme **Tokyo Night** đồng bộ toàn bộ.

| | |
|---|---|
| 🌐 Hệ thống | NixOS 26.05 (x86_64-linux) |
| 🪟 Desktop | Sway + Waybar + Mako (thông báo) |
| 🎨 Terminal | Foot |
| ⌨️ Bộ gõ | Fcitx5 + Unikey |
| 💾 Hibernate | Swap 10G — lưu trạng thái khi tắt máy |

---

## 🚀 Rebuild & Cập nhật

```bash
cd nix-config
git pull --rebase        # lấy code mới nhất
nix fmt                   # format *.nix (nixfmt)
sudo nixos-rebuild switch --flake .#laptop   # hoặc: nh os switch
```

> Một lệnh duy nhất cập nhật **cả NixOS lẫn home-manager** (home-manager được gắn qua `home-manager.nixosModules` trong `hosts/laptop/default.nix`).

---

## 🗂️ Cấu trúc thư mục

```
nix-config/
├── flake.nix                    # Điểm vào: nixpkgs + home-manager, đích build "laptop"
├── hosts/laptop/                # Cấu hình riêng cho máy laptop
│   ├── default.nix              # Import modules + gắn home-manager
│   └── hardware-configuration.nix  # Tự sinh khi cài máy
├── home/                        # Home Manager (user-level)
│   ├── default.nix              # Entry point: imports + PATH ~/.local/bin
│   ├── sway.nix                 # Sway: cửa sổ, phím tắt, idle/lock/sleep
│   ├── scripts.nix              # Script ~/.local/bin (power-menu, quick-lang…)
│   └── ...                      # waybar, foot, gtk, mako, fcitx5, pomodoro, thunar, remnote
├── modules/nixos/               # Module NixOS (system-level)
│   ├── core.nix                 # Nền tảng: Nix/flake, boot, mạng, user
│   ├── desktop.nix              # Sway/greetd, PipeWire, Fcitx5, fonts
│   ├── development.nix          # VS Code, Python, GCC, podman…
│   ├── laptop.nix               # Hibernate (resume=UUID=), zram, keyd, battery threshold — swap nằm trong hardware-config
│   └── system-tweaks.nix        # earlyoom, fstrim, nix-ld
├── docs/                        # 📚 Tài liệu tiếng Việt (xem bên dưới)
└── wallpapers/                  # Ảnh nền sáng/tối + ảnh khóa màn hình
```

---

## 📚 Tài liệu chi tiết

Bắt đầu từ hub [`docs/README.md`](docs/README.md):

| Bài | Nội dung |
|---|---|
| [Tổng quan hệ thống](docs/01-Tong-Quan-He-Thong.md) | Repo bố trí thế nào, Config vs Dữ liệu |
| [Vận hành hằng ngày](docs/02-Van-Hanh-Hang-Ngay.md) | Rebuild, scripts, lock/sleep, hibernate, sự cố |
| [Cài máy mới từ đầu](docs/03-Cai-May-Moi.md) | USB → phân vùng → install → kiểm tra hibernate |
| [Sao lưu & Khôi phục](docs/04-Sao-Luu-Phuc-Hoi.md) | Backup dữ liệu trước khi cài lại |
| [Từ điển thuật ngữ](docs/05-Tu-Dien-Thuat-Ngu.md) | Tra thuật ngữ Nix / Sway / Hibernate |
| [RemNote AppImage](docs/REMNODE.md) | Cài & cập nhật RemNote |

---

## 💡 Tính năng nổi bật

| Tính năng | Mô tả |
|---|---|
| **ZRAM** | Swap nén zstd 50% RAM — nhanh hơn SSD, giảm mòn ổ |
| **Hibernate** | `systemctl hibernate` — lưu toàn bộ RAM vào swap 10G rồi tắt máy, bật lại khôi phục nguyên trạng |
| **Battery threshold** | Sạc giới hạn 85–90% |
| **keyd** | Caps Lock = Ctrl (giữ) / Esc (chạm) |
| **Power profiles** | battery-saver / balanced / performance |
| **earlyoom** | Giết tiến trình ngốn RAM trước khi treo desktop |
| **fwupd** | Cập nhật firmware |
