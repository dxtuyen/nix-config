# Tái tạo hệ thống NixOS trên máy mới

Mục tiêu: cài NixOS mới và dùng lại cấu hình trong repo này. Hướng dẫn này giả
định bạn muốn thay toàn bộ hệ điều hành trên ổ đĩa. Nếu muốn dual boot, dừng và
lập kế hoạch phân vùng riêng trước — chọn nhầm ổ/phân vùng có thể mất dữ liệu.

## Trước khi bắt đầu

1. Sao lưu Documents, Downloads, ảnh, SSH key, mã 2FA, password manager,
   bookmark và mọi dữ liệu quan trọng.
2. Đảm bảo repo đã được đẩy lên GitHub và bao gồm `flake.lock`.
3. Ghi lại URL repo, ví dụ:

   ```text
   https://github.com/USERNAME/nix-config.git
   ```

4. Tạo USB cài NixOS từ ISO GNOME chính thức. Dùng bản GNOME giúp có sẵn giao
   diện Wi-Fi và terminal trong giai đoạn cài.

## Cài NixOS cơ bản

1. Boot từ USB ở chế độ UEFI.
2. Mở **Install NixOS**, kết nối Wi-Fi nếu cần.
3. Chọn ngôn ngữ/bàn phím và chọn ổ đĩa cẩn thận.
4. Nếu thay hệ điều hành cũ hoàn toàn, chọn **Erase disk**.
5. Tạo user có tên `doxuantuyen` để khớp với cấu hình hiện tại.
6. Hoàn tất cài đặt, reboot và rút USB.

Sau lần boot đầu, bạn có thể vào GNOME tạm thời. Đó là bình thường; Sway sẽ
được cấu hình ở bước tiếp theo.

## Lấy cấu hình và phần cứng của máy mới

Mở terminal, kết nối Internet, rồi chạy. Thay `USERNAME` bằng GitHub username
của bạn.

```bash
git clone https://github.com/USERNAME/nix-config.git ~/nix-config
cp /etc/nixos/hardware-configuration.nix ~/nix-config/hosts/laptop/hardware-configuration.nix
cd ~/nix-config
```

Lệnh `cp` là bắt buộc: file phần cứng chứa phân vùng, kernel module và driver
của **máy mới**. Không dùng `hardware-configuration.nix` của máy cũ.

Kiểm tra cấu hình trước:

```bash
nix --extra-experimental-features 'nix-command flakes' flake check --no-build
```

Nếu không có lỗi, dựng hệ thống:

```bash
sudo nixos-rebuild switch --flake .#laptop
```

Lần đầu sẽ tải khá nhiều package. Không tắt máy khi lệnh đang chạy. Khi hoàn
tất, reboot:

```bash
reboot
```

## Sau khi vào Sway

- `Super + Enter`: mở terminal.
- `Super + D`: mở menu ứng dụng.
- Mở Chrome, VS Code hoặc Thunar bằng menu này.
- Phím media điều chỉnh âm lượng, mic và độ sáng; popup sẽ cập nhật giá trị.

## Lưu phần cứng của máy mới

Sau khi xác nhận Wi-Fi, màn hình, âm thanh và boot đều ổn, commit file phần
cứng mới để lần sau có thể tái tạo đúng:

```bash
cd ~/nix-config
git add hosts/laptop/hardware-configuration.nix flake.lock
git commit -m "Update hardware configuration"
git push
```

Nếu đây là **một máy khác** nhưng bạn vẫn muốn giữ máy cũ, đừng ghi đè host
`laptop`. Hãy tạo host mới (ví dụ `hosts/work-laptop`) và một cấu hình mới trong
`flake.nix`; khi đó cần chọn tên host mới trong `nixos-rebuild`.

## Nếu gặp lỗi

- `could not find a flake.nix`: bạn đang không đứng trong repo. Dùng
  `cd ~/nix-config` hoặc `--flake ~/nix-config#laptop`.
- Không có Wi-Fi: thử Ethernet hoặc USB tethering; không xóa hệ điều hành cũ
  trước khi biết máy có Internet.
- Rebuild lỗi: chép nguyên lỗi, đặc biệt các dòng đầu tiên có đường dẫn `.nix`.
- Bản mới làm desktop không vào được: chọn generation NixOS cũ ở boot menu rồi
  sửa repo và rebuild lại.
