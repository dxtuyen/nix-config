# Luyện cài NixOS bằng QEMU/KVM

Hướng dẫn này tạo một máy ảo riêng để thực hành cài NixOS bằng flake của repo. Mọi thao tác phân vùng và định dạng bên dưới chỉ nhắm tới đĩa ảo `training.qcow2`.

## Yêu cầu

- NixOS đã cài cấu hình này và đã chạy `sudo nixos-rebuild switch --flake .#laptop`.
- CPU hỗ trợ ảo hóa và tài khoản thuộc nhóm `kvm`.
- Kết nối mạng để tải ISO và các gói Nix.

Repo có sẵn QEMU/KVM, OVMF, `qemu-img` và lệnh `vm-nixos`.

## 1. Tải ISO và tạo đĩa ảo

```bash
mkdir -p ~/VMs/iso ~/VMs/disk
curl -L https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso \
  -o ~/VMs/iso/nixos-minimal.iso
qemu-img create -f qcow2 ~/VMs/disk/training.qcow2 30G
```

## 2. Khởi động trình cài đặt

```bash
vm-nixos iso
```

Lệnh này khởi chạy QEMU với UEFI, KVM, 3 GiB RAM và đĩa ảo. Trong trình cài đặt, mở terminal rồi chạy `sudo -i`.

## 3. Phân vùng đĩa ảo

Đĩa VirtIO trong máy ảo thường xuất hiện là `/dev/vda`. Xác nhận bằng `lsblk` trước khi tiếp tục.

```bash
cfdisk /dev/vda
```

Tạo bảng GPT với ba phân vùng: EFI 1 GiB, root khoảng 20 GiB và swap khoảng 4 GiB. Chỉ ghi thay đổi nếu `lsblk` xác nhận bạn đang thao tác trên `/dev/vda`.

Tạo filesystem và mount:

```bash
mkfs.fat -F 32 /dev/vda1
mkfs.ext4 -L nixos /dev/vda2
mkswap -L swap /dev/vda3

mount /dev/vda2 /mnt
mount --mkdir /dev/vda1 /mnt/boot
swapon /dev/vda3
nixos-generate-config --root /mnt
```

## 4. Cài flake trong bản clone tạm

Tạo bản clone riêng trong môi trường cài đặt. Không thay file phần cứng của repo đang dùng trên laptop:

```bash
git clone https://github.com/dxtuyen/nix-config.git /tmp/nix-config-vm
cp /mnt/etc/nixos/hardware-configuration.nix \
  /tmp/nix-config-vm/hosts/laptop/hardware-configuration.nix
cd /tmp/nix-config-vm
```

Đặt mật khẩu user trong hệ thống mới rồi cài:

```bash
sudo nixos-enter --root /mnt -c 'passwd doxuantuyen'
sudo nixos-install --flake .#laptop
reboot
```

Tháo ISO khỏi boot hoặc đóng cửa sổ VM sau khi máy ảo khởi động lại.

## 5. Khởi động lại máy ảo

Sau khi cài xong, trên máy chủ chạy:

```bash
vm-nixos
```

Mặc định lệnh khởi động từ đĩa. Chạy `vm-nixos iso` để vào lại ISO. Muốn thực hành từ đầu, tạo một file đĩa mới hoặc đổi tên đĩa cũ trước khi tạo lại.

## Khắc phục nhanh

- **QEMU báo không truy cập được KVM:** đăng xuất rồi đăng nhập lại sau khi thêm user vào nhóm `kvm`; kiểm tra `ls -l /dev/kvm`.
- **VM chạy chậm:** kiểm tra QEMU có dùng KVM acceleration hay không.
- **Không thấy `/dev/vda`:** kiểm tra lại ổ đĩa bằng `lsblk` trước khi phân vùng.
- **Không khởi động được UEFI:** `vm-nixos` đã dùng OVMF; kiểm tra ISO và đĩa ảo đã tạo đúng vị trí.

Đây là môi trường luyện tập. Ghi chú cài máy thật nằm riêng tại [personal/cai-laptop.md](personal/cai-laptop.md).
