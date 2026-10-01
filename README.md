# 🖥️ NixOS Config — Doxuan Tuyen

Cấu hình **NixOS + Home-Manager** cho laptop cá nhân, chạy **Sway** (Wayland), theme **Catppuccin Mocha** đồng bộ toàn bộ (GTK dùng adw-gtk3-dark trung tính).

| | |
|---|---|
| 🌐 Hệ thống | NixOS unstable (x86_64-linux, rolling release) |
| 🪟 Desktop | Sway + Waybar + Mako (thông báo) |
| 🎨 Terminal | Foot + Starship |
| 🖼️ Xem ảnh / video | imv (ảnh) • mpv (video) • foliate (sách điện tử) • sioyek (PDF) |
| ⌨️ Bộ gõ | Fcitx5 + Bamboo |
| 💾 Hibernate | Swap 10G — lưu trạng thái khi tắt máy |

---

## 🚀 Rebuild & Cập nhật

Bật kiểm tra tự động trước mỗi lần push (chạy một lần trên mỗi clone):

```bash
git config core.hooksPath .githooks
```

Hook kiểm tra đúng commit sắp push bằng hai lệnh CI: `nix fmt -- --check` và `nix flake check --no-build`. Nếu format sai, chạy `nix fmt`, xem lại thay đổi, commit rồi push lại.

```bash
cd nix-config
git pull --rebase        # lấy code mới nhất
nix fmt                   # format *.nix (nixfmt)
sudo nixos-rebuild switch --flake .#laptop   # hoặc: nh os switch
# Sau khi shell alias đã được cập nhật: nswitch (từ đâu cũng cd vào repo và rebuild theo hostname)
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
│   ├── default.nix              # Thiết lập user + imports ba nhóm bên dưới
│   ├── config/                  # Cấu hình desktop, gói user và ứng dụng mặc định
│   ├── apps/                    # Tích hợp từng ứng dụng (Countdown, RemNote, Yazi…)
│   └── script/                  # Mọi lệnh ~/.local/bin, mỗi lệnh một file riêng
│       ├── default.nix          # Danh sách import các script
│       ├── quick-lang.nix       # Model, prompt và Gemini API
│       └── ...                  # countdown, countdown-engine, setup-remnote, wallpaper-set…
├── modules/nixos/               # Module NixOS (system-level)
│   ├── core.nix                 # Nền tảng: Nix/flake, boot, mạng, user
│   ├── desktop.nix              # Sway/greetd, PipeWire, Fcitx5, fonts
│   ├── development.nix          # VS Code, Python, GCC, podman…
│   ├── laptop.nix               # Hibernate (resume=/dev/disk/by-label/swap), zram, keyd, battery threshold — swap theo nhãn
│   └── system-tweaks.nix        # earlyoom, fstrim, nix-ld
├── docs/                        # 📚 Tài liệu tiếng Việt (xem bên dưới)
└── lockscreen/                  # 🖼️ Ảnh khoá màn hình (swaylock) — ảnh DUY NHẤT còn trong repo
```

> 🖼️ **Ảnh nền KHÔNG nằm trong repo**: `~/Pictures/wallpapers/` là thư mục của bạn, tự `cp`/`rm`, không rebuild. Xem [docs/02](docs/02-Van-Hanh-Hang-Ngay.md#ảnh-nền-wallpaper).

---

## 📚 Tài liệu chi tiết

Bắt đầu từ hub [`docs/README.md`](docs/README.md):

| Bài | Nội dung |
|---|---|
| [Tổng quan hệ thống](docs/01-Tong-Quan-He-Thong.md) | Repo bố trí thế nào, Config vs Dữ liệu |
| [Vận hành hằng ngày](docs/02-Van-Hanh-Hang-Ngay.md) | Rebuild, scripts, lock/sleep, hibernate, sự cố |
| [Cài máy mới từ đầu](docs/03-Cai-May-Moi.md) | USB → phân vùng → install → hibernate → **Bước 10: Git & SSH** |
| [Sao lưu & Khôi phục](docs/04-Sao-Luu-Phuc-Hoi.md) | Backup dữ liệu trước khi cài lại |
| [Từ điển thuật ngữ](docs/05-Tu-Dien-Thuat-Ngu.md) | Tra thuật ngữ Nix / Sway / Hibernate |
| [Luyện VM](docs/06-Luyen-Tap-VM.md) | Tập cài máy bằng máy ảo (QEMU/KVM) |
| [RemNote AppImage](docs/REMNOTE.md) | Cài & cập nhật RemNote |

---

## 💡 Tính năng nổi bật

| Tính năng | Mô tả |
|---|---|
| **ZRAM** | Swap nén zstd 50% RAM — nhanh hơn SSD, giảm mòn ổ |
| **Hibernate** | `systemctl hibernate` — lưu toàn bộ RAM vào swap 10G rồi tắt máy, bật lại khôi phục nguyên trạng |
| **Battery threshold** | Sạc giới hạn 85–90% |
| **keyd** | Caps Lock = Ctrl (giữ) / Esc (chạm) · **Tab giữ** = nav layer: hjkl mũi tên, `[`/`]` = Home/End (Tab chạm vẫn là Tab) |
| **Power profiles** | battery-saver / balanced / performance |
| **earlyoom** | Giết tiến trình ngốn RAM trước khi treo desktop |
| **fwupd** | Cập nhật firmware |
