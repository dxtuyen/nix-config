# Ghi chú cài laptop cá nhân

> Tài liệu riêng cho laptop của tác giả, không phải hướng dẫn cài đặt chung. Bố cục đĩa, tên user và cấu hình máy bên dưới phản ánh thiết bị hiện tại. Nếu mục tiêu là luyện tập, hãy dùng [hướng dẫn QEMU/KVM](../06-Luyen-Tap-VM.md).

## Cấu hình phần cứng dự kiến

- Khởi động UEFI, ổ NVMe `/dev/nvme0n1`, RAM khoảng 8 GiB.
- EFI: 1 GiB (`p1`), swap: 10 GiB (`p2`, nhãn `swap`), root: phần dung lượng còn lại (`p3`, ext4, nhãn `nixos`).
- Flake target: `laptop`; user: `doxuantuyen`.

**Cảnh báo:** các lệnh phân vùng và format sẽ xóa dữ liệu trên thiết bị được chỉ định. Kiểm tra tên ổ bằng `lsblk` và sao lưu dữ liệu trước khi tiếp tục. Không chạy lệnh nếu thiết bị không đúng là ổ đĩa cần cài.

## 1. Khởi động USB cài đặt

Tải ISO NixOS minimal, ghi vào USB bằng công cụ phù hợp, khởi động máy từ USB ở chế độ UEFI, rồi mở root shell:

```bash
sudo -i
```

Nếu cần Wi-Fi, kết nối bằng `iwctl` rồi xác nhận mạng bằng `ping -c 3 google.com`.

## 2. Phân vùng và tạo filesystem

Xác nhận ổ đĩa trước:

```bash
lsblk
```

Trên đúng ổ `/dev/nvme0n1`, tạo bảng GPT và ba phân vùng theo bố cục phía trên. Sau đó tạo filesystem:

```bash
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap -L swap /dev/nvme0n1p2
mkfs.ext4 -L nixos /dev/nvme0n1p3
```

## 3. Mount và sinh cấu hình phần cứng

```bash
mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p2
nixos-generate-config --root /mnt
```

Kiểm tra file được sinh trong `/mnt/etc/nixos/hardware-configuration.nix`. UUID của `/` và `/boot` phải khớp với phân vùng vừa tạo; `swapDevices` phải trỏ tới swap mới.

## 4. Cài flake

```bash
git clone https://github.com/dxtuyen/nix-config.git /tmp/nix-config
cp /mnt/etc/nixos/hardware-configuration.nix \
  /tmp/nix-config/hosts/laptop/hardware-configuration.nix
sudo nixos-enter --root /mnt -c 'passwd doxuantuyen'
cd /tmp/nix-config
sudo nixos-install --flake .#laptop
reboot
```

Sau khi khởi động lại, tháo USB và đăng nhập bằng user `doxuantuyen`.

## 5. Kiểm tra sau cài đặt

```bash
swapon --show
lsblk -f
cat /proc/cmdline
```

Xác nhận swap có nhãn `swap` và kernel command line có thiết bị resume theo nhãn đó. Thử hibernate sau khi lưu công việc:

```bash
sudo systemctl hibernate
```

Nếu máy không hỗ trợ chế độ ngủ `deep`, kiểm tra `cat /sys/power/mem_sleep` và điều chỉnh `mem_sleep_default=deep` trong `modules/nixos/laptop.nix`.

## 6. Đưa repo về thư mục chính và cấu hình SSH

```bash
git clone https://github.com/dxtuyen/nix-config.git ~/nix-config
ssh-keygen -t ed25519 -C 'doxuantuyen-laptop'
cat ~/.ssh/id_ed25519.pub
```

Thêm public key vào GitHub, rồi đổi remote sang SSH:

```bash
cd ~/nix-config
git remote set-url origin git@github.com:dxtuyen/nix-config.git
ssh -T git@github.com
git pull --rebase
```

Không lưu private key, mật khẩu hoặc dữ liệu cá nhân vào repo.
