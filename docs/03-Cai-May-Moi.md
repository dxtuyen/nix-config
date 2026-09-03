# 03 — Cài máy mới từ đầu (Phân vùng + Cài đặt + Kiểm tra)

> Bài này hướng dẫn **cài từ đầu** lên một máy mới: phân vùng đĩa (GPT),
> tạo filesystem, mount, sinh `hardware-configuration.nix`, rồi áp config trong repo này.
> Mọi thứ đều là **từng lệnh copy-paste được**, kèm giải thích biến/UUID để bạn chủ động
> khi phần cứng khác đi.

---

## 🧙 Đối chiếu: wizard cài GUI ↔ file Nix của repo này

> Người quen cài Ubuntu/Windows hay hỏi: "còn màn hình chọn ngôn ngữ,
> tạo user, đặt mật khẩu đâu?". NixOS **không có wizard** — mọi lựa chọn đó
> là **khai báo vĩnh viễn trong file Nix** dưới đây: máy mới nào chạy
> `nixos-install` cũng ra y hệt. Chỉ **MẬT KHẨU** là phải đặt tay 1 lần
> (Chặng 4 / Bước 7.5) vì repo public không được chứa mật khẩu.

| Màn hình wizard GUI | Khai báo ở đâu | Giá trị hiện tại |
|---|---|---|
| Ngôn ngữ / Region | `modules/nixos/core.nix` → `i18n.defaultLocale` | `en_US.UTF-8` |
| Múi giờ | `core.nix` → `time.timeZone` | `Asia/Ho_Chi_Minh` |
| Bàn phím (TTY) | `core.nix` → `console.keyMap` | `us` |
| Username + họ tên | `core.nix` → `users.users.doxuantuyen` | `doxuantuyen` / "Doxuan Tuyen" |
| Quyền admin (sudo) | `core.nix` → `extraGroups` | `wheel` + `networkmanager` + `kvm` |
| Màn hình đăng nhập | `modules/nixos/desktop.nix` → `services.greetd` | tuigreet → Sway (không auto-login) |
| Bộ gõ tiếng Việt | `desktop.nix` → `i18n.inputMethod` | fcitx5 + unikey |
| **Mật khẩu user** | ❌ không có trong config (cố ý) | **đặt tay ở Bước 7.5** |

---

## 🎯 Tổng quan & sơ đồ phân vùng mục tiêu

Máy mục tiêu: **laptop UEFI**, ổ **NVMe 238.5 GB**, **RAM 7.4 GB** (giống máy này).

Sơ đồ phân vùng mục tiêu (`/dev/nvme0n1`):

| Phân vùng | Kích thước | FS / Loại | Mount | Mục đích |
|---|---|---|---|---|
| `/dev/nvme0n1p1` | **1 GiB** | vfat (FAT32) — `EFI System` | `/boot` | systemd-boot (bootloader) |
| `/dev/nvme0n1p2` | **~227 GiB** | ext4 — `Linux root (x86)` | `/` | Hệ điều hành |
| `/dev/nvme0n1p3` | **10 GiB** | swap — `Linux swap` | `[SWAP]` | Swap + **Hibernate** |

> ⚠️ **Quy tắc vàng cho Hibernate:** phân vùng swap phải **≥ RAM** vì lúc hibernate,
> kernel nén toàn bộ RAM vào swap rồi tắt máy. Máy có RAM 7.4 GB → swap 10 GB là đủ.

---

## 🔤 Các biến dùng xuyên suốt

| Biến | Giá trị máy này | Ý nghĩa |
|---|---|---|
| `DISK` | `/dev/nvme0n1` | Ổ đĩa gốc (NVMe đầu tiên) |
| `EFI` | `/dev/nvme0n1p1` | Phân vùng EFI 1 GiB |
| `ROOT` | `/dev/nvme0n1p2` | Phân vùng root (ext4) |
| `SWAP` | `/dev/nvme0n1p3` | Phân vùng swap (10 GiB) |
| `SWAP_UUID` | `044520bf-eed9-498c-a382-97615c111b1f` | UUID của `SWAP` — phải khớp cả `hardware-configuration.nix` (swapDevices) lẫn `resume=UUID=` trong `laptop.nix` |

> Nếu máy mới dùng ổ SATA (`/dev/sda`…) thì chỉ cần đổi tên thiết bị, còn UUID và các file vẫn như thường.

---

## ✅ Bước 0 — Chuẩn bị

1. Tải **ISO NixOS minimal** (26.05):
   > https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso
2. USB ≥ 2 GB.
3. Có mạng (wifi dùng `iwctl`, xem Bước 2).

---

## Bước 1 — Ghi ISO vào USB

```bash
# Xác định USB (VD: đừng nhầm với ổ cứng!)
lsblk

# Ghi ISO (thay /dev/sdX bằng tên USB của bạn)
sudo dd if=nixos-minimal-26.05-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

---

## Bước 2 — Boot USB & vào quyền root

1. Khởi động lại, bấm chọn boot (thường `F12`/`Esc`/`F2`) → chọn USB.
2. Chọn mục **NixOS** trong menu boot.
3. Khi có `[nixos@nixos:~]$`, vào **root** ngay:

```bash
sudo -i      # nếu chưa ở root
```

**Nếu dùng wifi (không có dây):**

```bash
iwctl                     # mở tool wifi
> station wlan0 connect "TEN_WIFI"
> exit
ping -c3 google.com       # kiểm tra mạng
```

---

## Bước 3 — Kiểm tra ổ trước khi đụng tới

```bash
# Liệt kê đĩa: cần thấy ổ TRỐNG định cài (không phải USB!)
lsblk
fdisk -l /dev/nvme0n1      # kiểm tra đĩa gốc

# Quan trọng: nếu máy đã có NixOS/Windows và muốn CÀI ĐÈ, hãy xoá bảng phân vùng cũ trước (CẢNH BÁO: mất toàn bộ dữ liệu)
wipefs -a /dev/nvme0n1
```

---

## Bước 4 — Phân vùng bằng `cfdisk`

```bash
cfdisk /dev/nvme0n1
```

Trong giao diện `cfdisk` (chọn kiểu bảng: **`gpt`**):

| Thao tác | Phím | Kết quả |
|---|---|---|
| Bảng mới | `s` → chọn `gpt` | Bảng GPT |
| Tạo `p1` EFI 1 GiB | `[New]` → `1G` → `[Type]` → `EFI System` | `p1` 1G |
| Tạo `p2` root | `[New]` → nhập `227G` (hoặc để trống = hết đĩa) → `[Type]` → `Linux root (x86)` | `p2` 227G |
| Tạo `p3` swap | `[New]` → `10G` → `[Type]` → `Linux swap` | `p3` 10G |
| Ghi | `[Write]` → gõ `yes` → `[Quit]` | Lưu xong thoát |

> Mẹo: máy ổ to, chỉ cần `p1` + `p3` đủ kích thước, còn `p2` **để trống Size** — cfdisk sẽ lấy hết phần còn lại.

Kiểm tra:

```bash
lsblk      # phải thấy nvme0n1p1 / p2 / p3 đúng size
```

---

## Bước 5 — Tạo filesystem cho từng phân vùng

```bash
# p1 — EFI: FAT32 (bắt buộc cho UEFI)
mkfs.fat -F 32 /dev/nvme0n1p1

# p2 — root: ext4
mkfs.ext4 -L nixos /dev/nvme0n1p2

# p3 — swap
mkswap -L swap /dev/nvme0n1p3

# 🔑 Lấy UUID của swap — ghi lại để dùng ở Bước 7
blkid /dev/nvme0n1p3
```

`blkid` in ra dạng:

```
/dev/nvme0n1p3: LABEL="swap" UUID="044520bf-..." TYPE="swap"
```

> **UUID = ID cố định của phân vùng**, không đổi kể cả khi đổi thứ tự/cắm đĩa khác.
> Config NixOS tham chiếu bằng UUID (`/dev/disk/by-uuid/...`) nên an toàn hơn dùng
> `/dev/nvme0n1p3`. Mỗi máy có UUID khác nhau → bạn **phải đồng bộ** ở Bước 7.

---

## Bước 6 — Mount & sinh `hardware-configuration.nix`

```bash
# Mount root mới vào /mnt
mount /dev/nvme0n1p2 /mnt

# Mount /boot bên trong
mount --mkdir /dev/nvme0n1p1 /mnt/boot

# Bật swap (để nixos-generate-config phát hiện phân vùng swap)
swapon /dev/nvme0n1p3

# Kiểm tra mounts + swap
findmnt /mnt
findmnt /mnt/boot
swapon --show

# Sinh file cấu hình phần cứng tự động
nixos-generate-config --root /mnt

# Xem file vừa sinh
cat /mnt/etc/nixos/hardware-configuration.nix
```

Những gì file vừa sinh chứa:
- `fileSystems."/"` → UUID của `p2`.
- `fileSystems."/boot"` → UUID của `p1`.
- `swapDevices` → vì bạn đã `swapon` trước khi chạy `nixos-generate-config`, mục này sẽ **tự điền đúng phân vùng swap** — chính là nơi khai swap duy nhất.

---

## Bước 7 — Áp dụng config trong repo này

### 7.1 Clone repo vào installer

```bash
git clone https://github.com/dxtuyen/nix-config.git /tmp/nix-config
cd /tmp/nix-config
```

### 7.2 Copy `hardware-configuration.nix` mới vào repo

```bash
cp /mnt/etc/nixos/hardware-configuration.nix \
   /tmp/nix-config/hosts/laptop/hardware-configuration.nix
```

File này mang **UUID root + boot của máy mới** — tự sinh nên không cần sửa tay.

### 7.3 Swap — tự khớp nhờ `hardware-configuration.nix` (không cần sửa!)

Bản thiết kế: `swapDevices` được khai trong `hosts/laptop/hardware-configuration.nix`
(file **tự sinh** bởi `nixos-generate-config` ở Bước 6). Vì bạn đã `swapon` trước khi
chạy lệnh sinh config, file này sẽ **tự điền đúng UUID swap của máy mới** →
không phải sửa gì về swap. Kiểm tra nhanh:

```bash
grep -A4 swapDevices /tmp/nix-config/hosts/laptop/hardware-configuration.nix
# phải thấy UUID khớp với `blkid` ở Bước 5
```

### 7.4 Đồng bộ **UUID swap** trong `modules/nixos/laptop.nix`

`laptop.nix` chỉ còn khai **1 chỗ** liên quan swap — tham số kernel `resume=UUID=`:

```nix
# --- Hibernation ---
boot.kernelParams = [
  "resume=UUID=044520bf-eed9-498c-a382-97615c111b1f"   # ← sửa UUID này cho khớp SWAP_UUID mới
];
```

> 🖥️ Thay `044520bf-...` bằng **`SWAP_UUID`** lấy ở Bước 5. Đây là tham số kernel
> báo swap nào chứa image hibernate — sai là hibernate không dậy được.
>
> **Tóm tắt mỗi lần sang máy mới (chỉ 2 việc về swap):**
> 1. `hosts/laptop/hardware-configuration.nix` → **thay nguyên file** bằng file mới sinh (7.2) → swap tự khớp.
> 2. `modules/nixos/laptop.nix` → **sửa `resume=UUID=`** (7.4).

### 7.5 (Tuỳ chọn) Đặt mật khẩu user trước khi reboot

Đặt mật khẩu cho `doxuantuyen` ngay từ installer (bằng không sau reboot
không đăng nhập được vào greetd):

```bash
sudo nixos-enter --root /mnt -c "passwd doxuantuyen"
```

> Cách khác: sau reboot login root ở TTY (`Ctrl+Alt+F2`, user `root`) → `passwd doxuantuyen`.

---

## Bước 8 — Cài đặt hệ thống

```bash
cd /tmp/nix-config
sudo nixos-install --flake .#laptop
```

Diễn giải:
- `--flake .#laptop` → dùng config `nixosConfigurations.laptop` trong `flake.nix`.
- Cài **cả NixOS lẫn home-manager** (đã gắn trong `hosts/laptop/default.nix`).
- Nếu chưa đặt mật khẩu root ở 7.5, máy sẽ hỏi → đặt 2 lần.
- Chờ build xong (tải nixpkgs + home-manager từ network) rồi reboot:

```bash
reboot
```

Rút USB khi thấy menu systemd-boot.

---

## Bước 9 — Kiểm tra hệ thống mới + Hibernate

Sau khi vào desktop (Sway), mở terminal và kiểm tra theo thứ tự:

1. **Swap hoạt động**: `swapon --show` phải thấy `/dev/nvme0n1p3` (10G), và `cat /proc/swaps`.
2. **Kernel có `resume`**: `cat /proc/cmdline` phải chứa `resume=UUID=<SWAP_UUID>`.
3. **Phân vùng đúng**: `lsblk -f`.
4. **Clone repo về máy** để lần sau rebuild tại chỗ: `git clone https://github.com/dxtuyen/nix-config.git ~/nix-config`.
5. **Thử hibernate**: chạy `sudo systemctl hibernate` — máy lưu tất cả cửa sổ rồi tắt nguồn; bật lại, đăng nhập, mọi thứ khôi phục nguyên trạng.
6. **Chế độ ngủ (deep sleep)**: chạy `cat /sys/power/mem_sleep`.
   - Thấy `s2idle [deep]` → máy hỗ trợ deep (S3), giữ nguyên config. ✓
   - Chỉ thấy `[s2idle]` → máy **không hỗ trợ** deep. Kernel tự bỏ qua tham số
     nên không lỗi gì cả; chỉ cần **xóa dòng `"mem_sleep_default=deep"`**
     trong `modules/nixos/laptop.nix` rồi rebuild cho gọn.

---

## Bước 10 — Git & SSH: đưa repo về "nhà" mới

> Mục tiêu: sau bước này, `~/nix-config` **pull/push bằng SSH** như thường.
> Chánh đạo là **Đường B — tạo SSH key mới cho máy mới**: không cần backup key,
> không đụng tới máy cũ, mất ~2 phút.

### 10.1 Máy mới đã có sẵn gì về Git?

Máy đã cài xong thì mọi thứ Git đều có sẵn (không cấu hình gì thêm):

| Thứ | Nơi khai báo |
|---|---|
| Gói `git` | `modules/nixos/core.nix` (`environment.systemPackages`) |
| Identity commit (user `dxtuyen`, email `tuyendoxuan05@gmail.com`) | `home/git.nix` (`programs.git`) |
| ssh-agent (giữ passphrase, chỉ hỏi 1 lần/phiên) | `programs.ssh.startAgent` trong `core.nix` |

Chỉ khi còn ở **USB installer** mà gõ `git` báo "command not found", dùng tạm:

```bash
nix-shell -p git   # git dùng tạm trong shell, không cài vào hệ thống
```

### 10.2 Đường B — tạo SSH key mới cho máy mới (chánh đạo)

Nguyên tắc: **mỗi máy một key riêng**. Key cũ trên GitHub cứ để nguyên —
không cần xoá, không cần backup, không đụng tới máy cũ.

```bash
ssh-keygen -t ed25519 -C "doxuantuyen-laptop"   # Enter hết để nhận mặc định
cat ~/.ssh/id_ed25519.pub                        # copy NGUYÊN DÒNG in ra
```

Add key lên GitHub — **bước duy nhất cần giao diện web** (GitHub phải đăng nhập
mới duyệt key; máy mới chưa push được bằng SSH nên không thể tự động hoá):

1. Mở `https://github.com/settings/keys` — bằng **Chrome** (được cài sẵn bởi
   config) hoặc làm trên **điện thoại**
2. Bấm `New SSH key` → Title tuỳ ý (VD `laptop-moi`) → dán key → `Add SSH key`

```bash
ssh -T git@github.com      # lần đầu hỏi fingerprint → gõ yes
# phải in ra: "Hi dxtuyen! You've successfully authenticated..."
```

### 10.3 Đổi remote sang SSH & kiểm tra tròn vòng

```bash
# Repo đã clone bằng HTTPS ở Bước 9 → chỉ cần đổi remote sang SSH:
cd ~/nix-config
git remote set-url origin git@github.com:dxtuyen/nix-config.git

# Kiểm tra tròn vòng — cả pull lẫn push phải thành công:
git pull --rebase && git push
```

> ⚠️ Repo nằm ở **`dxtuyen/nix-config`** (không phải `doxuantuyen`) — copy đúng URL.
> Nếu `ssh -T` thành công mà `git pull/push` vẫn hỏi mật khẩu → remote còn là
> HTTPS, kiểm tra bằng `git remote -v`.

### 10.4 Đường A — khôi phục key cũ (nếu lỡ có backup `~/.ssh`)

Hợp lý khi bạn có nhiều máy dùng chung một key, hoặc đã có sẵn file backup
(từ [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md)):

```bash
rsync -a /mnt/backup/.ssh ~/.ssh          # hoặc: tar xzf backup-personal.tar.gz -C ~
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519               # private key PHẢI 600, nếu không ssh từ chối
chmod 644 ~/.ssh/id_ed25519.pub ~/.ssh/known_hosts
ssh -T git@github.com                     # → nhảy tới 10.3, khỏi add key mới
```

> Key cũ vẫn nằm sẵn trong danh sách SSH keys trên GitHub → không phải add gì thêm.

---

## 🔩 Tóm tắt lệnh nhanh (cả phiên cài)

> Bản tham khảo nhanh gồm **6 chặng**. Mỗi lệnh kèm `# ✅ KIỂM TRA:` — đầu ra
> mong đợi để biết đang đúng đường. Sai ở chặng nào → tra bảng
> **Sự cố thường gặp** bên dưới hoặc quay lại Bước chi tiết tương ứng
> (ghi trong mỗi tiêu đề chặng).

### Chặng 0 — Vào root + mạng (Bước 2)

```bash
sudo -i        # dấu nhắc đổi thành [root@nixos:~]# — từ đây mọi lệnh chạy với root

# nếu wifi (không có dây):
iwctl
> station wlan0 connect "TEN_WIFI"
> exit

ping -c3 google.com
# ✅ KIỂM TRA: "3 packets transmitted, 3 received" → mạng OK, được phép tiếp tục
# ❌ 0 received → kiểm tra tên/mật khẩu wifi, hoặc thử dây mạng
```

### Chặng 1 — Phân vùng (Bước 4)

```bash
cfdisk /dev/nvme0n1    # chọn bảng gpt
# Trong cfdisk: p1 = 1G (EFI System) → p2 = 227G (Linux root x86)
#               → p3 = 10G (Linux swap) → [Write] gõ yes → [Quit]

lsblk
# ✅ KIỂM TRA: thấy đủ 3 dòng:
#   nvme0n1p1   1G
#   nvme0n1p2 227G    (hoặc hết phần đĩa còn lại)
#   nvme0n1p3  10G
# ❌ thiếu p3 / size sai → vào lại cfdisk sửa NGAY trước khi format
```

### Chặng 2 — Filesystem + lấy SWAP_UUID (Bước 5)

```bash
mkfs.fat -F 32 /dev/nvme0n1p1    # EFI — in "mkfs.fat 4.2 ..." là xong
mkfs.ext4 -L nixos /dev/nvme0n1p2
# ✅ KIỂM TRA: khối "Creating filesystem with ... blocks" chạy xong không báo lỗi

mkswap -L swap /dev/nvme0n1p3
blkid /dev/nvme0n1p3
# ✅ KIỂM TRA: in ra dòng kiểu:
#   /dev/nvme0n1p3: LABEL="swap" UUID="044520bf-eed9-..." TYPE="swap"
# 📝 GHI RA GIẤY chuỗi UUID trên = SWAP_UUID — Chặng 4 phải dùng đúng nó
```

### Chặng 3 — Mount + sinh config phần cứng (Bước 6)

```bash
mount /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p3

findmnt /mnt          # ✅ SOURCE=/dev/nvme0n1p2, FSTYPE=ext4
findmnt /mnt/boot     # ✅ SOURCE=/dev/nvme0n1p1, FSTYPE=vfat
swapon --show         # ✅ có /dev/nvme0n1p3, SIZE 10G

nixos-generate-config --root /mnt
# ✅ KIỂM TRA: in "writing /mnt/etc/nixos/hardware-configuration.nix" (không warning swap)
# ❌ file không có swapDevices → quên swapon ở trên; bật lại rồi chạy generate lần nữa
```

### Chặng 4 — Clone repo + đồng bộ UUID + ĐẶT MẬT KHẨU (Bước 7)

```bash
git clone https://github.com/dxtuyen/nix-config.git /tmp/nix-config
# ❌ "git: command not found" → chạy nix-shell -p git rồi clone lại (Bước 10.1)

cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nix-config/hosts/laptop/

grep -A4 swapDevices /tmp/nix-config/hosts/laptop/hardware-configuration.nix
# ✅ KIỂM TRA: UUID in ra TRÙNG KHỚP với SWAP_UUID đã ghi ở Chặng 2

# Sửa đúng 1 dòng trong modules/nixos/laptop.nix:
#   boot.kernelParams = [ "resume=UUID=<SWAP_UUID_của_máy_này>" ]
# Dòng "mem_sleep_default=deep": giữ nguyên — sau reboot kiểm tra Bước 9 mục 6,
#   máy mới không hỗ trợ S3 (chỉ thấy [s2idle]) thì xoá dòng này đi.

sudo nixos-enter --root /mnt -c "passwd doxuantuyen"
# ✅ KIỂM TRA: gõ mật khẩu 2 lần → "password updated successfully"
# ⚠️ BỎ QUA BƯỚC NÀY = sau reboot KHÔNG đăng nhập được vào máy!
```

### Chặng 5 — Cài + reboot (Bước 8)

```bash
cd /tmp/nix-config
sudo nixos-install --flake .#laptop
# Máy tải nixpkgs + home-manager từ mạng (vài GB, 10–30 phút tuỳ mạng),
# in liên tục "building '/nix/store/...'" — đó là bình thường, chờ nhé.
# ✅ KIỂM TRA xong in: "installation finished!"
# ❌ build fail / báo unit swap → chụp lỗi, tra bảng Sự cố thường gặp
# (nếu chưa đặt mật khẩu root, lệnh hỏi đặt 2 lần — nhớ kỹ mật khẩu này)

reboot        # rút USB khi thấy menu systemd-boot
```

### Chặng 6 — Sau reboot: đăng nhập + Git & SSH (Bước 9 + 10)

```bash
# Màn hình tuigreet: user doxuantuyen + mật khẩu đã đặt ở Chặng 4 → vào Sway

swapon --show          # ✅ có /dev/nvme0n1p3
cat /proc/cmdline      # ✅ chứa resume=UUID=<SWAP_UUID>

# Git & SSH (chi tiết ở Bước 10):
ssh-keygen -t ed25519 -C "doxuantuyen-laptop"
# ✅ in ra hình randomart ASCII = key đã tạo tại ~/.ssh/id_ed25519

cat ~/.ssh/id_ed25519.pub
# ✅ một dòng dài bắt đầu "ssh-ed25519 AAAA..." — copy NGUYÊN DÒNG
#   → mở github.com/settings/keys (Chrome / điện thoại) → New SSH key → dán

ssh -T git@github.com          # lần đầu hỏi fingerprint → gõ yes
# ✅ in ra: "Hi dxtuyen! You've successfully authenticated, but GitHub does
#    not provide shell access."  ← chữ "Hi dxtuyen!" là dấu hiệu thành công

cd ~/nix-config && git remote set-url origin git@github.com:dxtuyen/nix-config.git
git pull --rebase && git push
# ✅ cả hai chạy xong KHÔNG hỏi mật khẩu/token → hoàn tất toàn bộ phiên cài 🎉
```

---

## 🛠️ Sự cố thường gặp

| Triệu chứng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Boot không thấy menu / không vào NixOS | Quên phân vùng EFI, hoặc bảng `dos` thay `gpt` | Làm lại Bước 4: bảng **GPT**, `p1` loại `EFI System` |
| `nixos-install` báo lỗi unit swap | `swapDevices` khai sai / trùng | Chỉ khai swap trong `hardware-configuration.nix` (file mới sinh tự đúng) |
| `nixos-generate-config` không thấy swap | Chưa `swapon` | Chạy `swapon /dev/nvme0n1p3` rồi sinh lại |
| Hibernate không dậy được | `resume=UUID=` sai/thiếu | Kiểm tra `blkid`, sửa `resume=UUID=` trong `laptop.nix`, rebuild |
| Swap nhỏ hơn RAM → hibernate lỗi | Vi phạm quy tắc vàng | Tăng swap ≥ RAM (Bước 4) |
| Ngủ tốn pin bất thường | Máy không hỗ trợ S3 → rơi về s2idle | Kiểm tra `cat /sys/power/mem_sleep`; xóa `"mem_sleep_default=deep"` trong `laptop.nix` (Bước 9 mục 6). Muốn tiết kiệm pin hơn: thử hibernate hoặc kiểm tra BIOS có bản cập nhật bật S3 |
| Không đăng nhập được user | Chưa đặt mật khẩu `doxuantuyen` | Login root ở TTY (`Ctrl+Alt+F2`) → `passwd doxuantuyen` |
| Quên copy `hardware-configuration.nix` | UUID root/boot cũ → lỗi boot | Copy file mới vào `hosts/laptop/` rồi rebuild |

---

## Liên quan

- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — repo này bố trí thế nào
- [02-Van-Hanh-Hang-Ngay](02-Van-Hanh-Hang-Ngay.md) — `nixos-rebuild switch` / `nh os switch` từ máy đã cài
- [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md) — **khôi phục dữ liệu** sau khi cài xong (bước tiếp theo!)
- Bước 10 vừa làm — Git & SSH: tạo key mới, đổi remote sang SSH
- [05-Tu-Dien-Thuat-Ngu](05-Tu-Dien-Thuat-Ngu.md) — UUID, flake, generation là gì
