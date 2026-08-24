# 06 — Luyện tập cài máy với Máy ảo (VM)

> Thực hành toàn bộ quy trình ở [03 — Cài máy mới](03-Cai-May-Moi.md) trong
> **máy ảo** trước khi chạy trên máy thật. An toàn 100%, làm lại bao nhiêu lần cũng được.

## Vì sao nên luyện trên VM

- **Không rủi ro**: đĩa ảo sai/mất hư giả chỉ cần xoá file là xong, máy thật không đụng.
- **Đúng quy trình**: VM dùng UEFI (OVMF) + đĩa GPT giống hệt máy thật → các bước `cfdisk`, `mkfs`, mount, `nixos-install`, reboot… giống y `docs/03`.
- **Tốc độ tốt**: máy bạn có CPU `vmx` + `/dev/kvm` → QEMU chạy gần native.

## Gói cần cài

Tất cả đã khai sẵn trong repo — chỉ cần rebuild, không cài tay:
- `home/packages.nix`: `qemu` (chạy VM), `qemu-utils` (`qemu-img`), `OVMF` (firmware UEFI)
- `modules/nixos/core.nix`: user đã vào group `kvm` (để dùng tăng tốc KVM)
- `home/scripts.nix`: script tiện ích `~/.local/bin/vm-nixos`

Sau khi chạy `sudo nixos-rebuild switch --flake .#laptop`, kiểm tra:

```bash
qemu-system-x86_64 --version
qemu-img --version
ls -la ~/.local/bin/vm-nixos
# Firmware UEFI resolve qua nix — phải in ra đường dẫn OVMF_CODE.fd trong /nix/store
nix eval --raw nixpkgs#OVMF.firmware; echo
```

## Bước 1 — Tải ISO NixOS

```bash
mkdir -p ~/VMs/iso ~/VMs/disk
cd ~/VMs/iso
curl -LO https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso
```

## Bước 2 — Tạo đĩa ảo (30G)

```bash
qemu-img create -f qcow2 ~/VMs/disk/training.qcow2 30G
```

> Dùng format `qcow2`: chỉ tốn dung lượng thật khi dùng (discard/sparse), hỗ trợ snapshot.

## Bước 3 — Chạy VM boot từ ISO (UEFI)

Cách dễ nhất — dùng script có sẵn (tự resolve firmware OVMF, tự tìm ISO/đĩa):

```bash
vm-nixos iso
```

Lệnh tương đương mà script chạy bên trong (để bạn hiểu cơ chế):

```bash
# Firmware UEFI — cách chuẩn trên NixOS: hỏi nix, KHÔNG find /nix/store
OVMF_CODE="$(nix eval --raw nixpkgs#OVMF.firmware)"

qemu-system-x86_64 \
  -machine q35,accel=kvm \
  -cpu host \
  -m 3G \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -boot d \
  -cdrom ~/VMs/iso/latest-nixos-minimal-x86_64-linux.iso \
  -drive file=~/VMs/disk/training.qcow2,if=virtio,format=qcow2 \
  -nic user,model=virtio \
  -display gtk
```

Giải thích:
- `accel=kvm` — dùng KVM (gần native). Nếu lỗi quyền: `ls -l /dev/kvm` và `id` (phải có group `kvm` — repo đã thêm sẵn trong `core.nix`).
- `-m 3G` — cấp 3G RAM cho VM. Trên VM nên tạo swap 4G (≥ RAM VM) để đúng quy tắc "swap ≥ RAM" của hibernate.
- `if=pflash ... OVMF_CODE.fd` — boot **UEFI** như máy thật; đường dẫn do `nix eval nixpkgs#OVMF.firmware` trả về nên luôn khớp phiên bản OVMF đang cài.
- `-boot d` — boot từ CD (ISO) trước.
- `-drive file=training.qcow2,if=virtio` — đĩa sẽ hiện là `/dev/vda` (VirtIO), khác `nvme0n1` máy thật — quan trọng là cơ chế giống, tên không sao.
- `-display gtk` — cửa sổ GUI để bạn gõ lệnh trong VM.

## Bước 4 — Trong VM: làm y hệt `docs/03`

Bây giờ terminal trong VM chính là "máy mới". Đi từng bước:

1. **Boot:** chọn *NixOS* trong menu, chờ về `[nixos@nixos:~]$`.
2. **Vào root:** `sudo -i`
3. **Phân vùng (GPT, 3 part):**

   ```bash
   cfdisk /dev/vda
   # p1: 1G EFI System
   # p2: 20G Linux root (x86)
   # p3: 4G  Linux swap
   # Write → Quit
   ```

4. **Filesystem:**
   ```bash
   mkfs.fat -F 32 /dev/vda1
   mkfs.ext4 -L nixos /dev/vda2
   mkswap -L swap /dev/vda3
   blkid /dev/vda3
   ```

5. **Mount + sinh config:**
   ```bash
   mount /dev/vda2 /mnt
   mount --mkdir /dev/vda1 /mnt/boot
   swapon /dev/vda3
   nixos-generate-config --root /mnt
   cat /mnt/etc/nixos/hardware-configuration.nix   # swap phải tự hiện
   ```

6. **Clone repo + apply config** (như docs/03 Bước 7):
   ```bash
   git clone https://github.com/dxtuyen/nix-config.git /tmp/nix-config
   cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nix-config/hosts/laptop/
   ```
   Rồi sửa `resume=UUID=` trong `modules/nixos/laptop.nix` theo swap của VM.

7. **Cài hệ thống** (chờ tải gói ~10–40 phút):
   ```bash
   cd /tmp/nix-config
   nixos-install --flake .#laptop
   reboot   # trong VM
   ```

## Bước 5 — Chạy lại VM từ đĩa đã cài

Sau khi VM cài xong và shutdown, boot lại từ **đĩa** (không cần ISO):

```bash
vm-nixos        # mặc định boot từ đĩa (tương đương -boot c thay vì -boot d ở Bước 3)
```

Muốn luyện lại từ đầu: tạo đĩa mới (`qemu-img create -f qcow2 ~/VMs/disk/training.qcow2 30G`) rồi `vm-nixos iso` — mỗi vòng chỉ mất vài phút chuẩn bị.

## Sự cố thường gặp (VM)

| Triệu chứng | Cách xử lý |
|---|---|
| `kvm` không có quyền | `sudo usermod -aG kvm $USER` rồi đăng xuất/đăng nhập lại; `ls -l /dev/kvm` |
| Cửa sổ GTK không hiện | dùng `-display gtk` hoặc `-display wayland` (tuỳ session); kiểm tra bạn đang ở Wayland |
| VM quá chậm | chắc chắn `accel=kvm` đang dùng (nếu không, QEMU sẽ báo warning TCG) |
| Không thấy `/dev/vda` | `-drive if=virtio` chưa đúng; kiểm tra `lsblk` trong VM |
| Không boot được UEFI | chắc chắn dùng `OVMF_CODE.fd` + `q35`; đừng dùng SeaBIOS mặc định |

## Gợi ý tiến độ

1. **Buổi 1:** Bước 1–3 — boot được VM từ ISO.
2. **Buổi 2:** Bước 4(1–5) — phân vùng + sinh config trong VM.
3. **Buổi 3:** Bước 4(6–7) — chạy `nixos-install` full + reboot đĩa.
4. **Buổi 4:** chạy lại nhiều lần tới khi thuộc quy trình → sang máy thật theo `docs/03` + `docs/04`.

## Liên quan

- [03-Cai-May-Moi](03-Cai-May-Moi.md) — quy trình thật đang được luyện
- [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md) — backup trước khi cài máy thật