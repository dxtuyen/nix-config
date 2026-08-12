# Học NixOS từ cấu hình này

Tài liệu này dùng chính repo này làm bài học. Mục tiêu không phải nhớ hết ngôn
ngữ Nix, mà là biết **file nào quản lý việc gì**, sửa chỗ nào, rồi áp dụng và
quay lui an toàn khi cần.

## Bức tranh tổng thể

```text
flake.nix
└── hosts/laptop/default.nix
    ├── modules/nixos/core.nix        # nền tảng hệ thống
    ├── modules/nixos/desktop.nix     # Sway, âm thanh, tiếng Việt, Bluetooth
    ├── modules/nixos/development.nix # công cụ học/lập trình
    ├── modules/nixos/laptop.nix      # pin, firmware, bàn phím laptop
    └── home/default.nix              # app và giao diện của doxuantuyen
```

NixOS xây toàn bộ hệ thống từ các file này. Thay vì cài từng app bằng lệnh rời
rạc, ta mô tả trạng thái mong muốn trong file `.nix`, rồi chạy rebuild.

## Đọc theo thứ tự này

### 1. `flake.nix`

Đây là điểm vào của repo. Nó ghim phiên bản NixOS và Home Manager trong
`flake.lock`, đồng thời khai báo máy tên `laptop`.

Chỉ cần nhớ: khi chạy `sudo nixos-rebuild switch --flake .#laptop`, `laptop`
chính là tên cấu hình ở đây.

### 2. `hosts/laptop/default.nix`

File này ghép các phần cấu hình lại cho chiếc laptop hiện tại. Khi có máy thứ
hai, hãy tạo thư mục host khác thay vì sửa lẫn với `laptop`.

### 3. Các file trong `modules/nixos/`

- `core.nix`: mạng, user, boot, garbage collection, các tool hệ thống cơ bản.
- `desktop.nix`: Sway, PipeWire, cổng desktop, Fcitx5/Unikey và font.
- `development.nix`: VS Code, Python, C/C++, Podman.
- `laptop.nix`: firmware update, giới hạn sạc pin và keyd.

Đây là nơi phù hợp cho những thứ liên quan đến cả hệ thống hoặc phần cứng.

### 4. `home/default.nix`

Đây là file bạn sẽ chỉnh nhiều nhất. Nó quản lý app dùng hằng ngày (Chrome,
Thunar...), Sway, Waybar, thông báo Mako và các phím tắt.

Muốn cài app mới, thêm tên package vào `home.packages`, ví dụ:

```nix
home.packages = with pkgs; [
  btop
];
```

Muốn thêm phím tắt Sway, tìm khối `wayland.windowManager.sway.extraConfig`.

## Quy trình sửa cấu hình hằng ngày

1. Vào repo và kiểm tra thay đổi:

   ```bash
   cd ~/nix-config
   git status
   ```

2. Sửa một việc nhỏ trong file `.nix`.
3. Kiểm tra cấu hình trước khi áp dụng:

   ```bash
   nix flake check --no-build
   ```

4. Áp dụng thay đổi:

   ```bash
   sudo nixos-rebuild switch --flake .#laptop
   ```

`switch` áp dụng ngay, nên không cần reboot trong đa số trường hợp. Đăng xuất/
đăng nhập lại nếu thay đổi phiên Sway, service người dùng hoặc môi trường input
method chưa có hiệu lực ngay.

5. Khi đã ổn, lưu lại:

   ```bash
   git add .
   git commit -m "Mo ta ngan gon thay doi"
   git push
   ```

Không commit mật khẩu, private key hay token vào repo.

## Khi xảy ra lỗi

- Rebuild lỗi: đọc dòng lỗi đầu tiên liên quan đến file của repo; không chạy
  lệnh xóa dữ liệu để “sửa nhanh”.
- Desktop lỗi sau rebuild: reboot, chọn generation NixOS cũ trong boot menu.
- Muốn quay lại ngay generation trước:

  ```bash
  sudo nixos-rebuild switch --rollback
  ```

- Muốn xem các generation hiện có:

  ```bash
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
  ```

## Những nguyên tắc đáng giữ

- Cài app lâu dài bằng Nix, không dùng `sudo pip install` hoặc script cài đặt
  không rõ nguồn gốc.
- Python theo từng project: dùng `.venv` trong thư mục project.
- Sửa nhỏ, rebuild, kiểm tra, rồi commit — cách này dễ tìm lỗi hơn sửa nhiều
  thứ một lúc.
- `hardware-configuration.nix` là riêng cho từng máy; không sao chép file đó
  sang máy khác.
