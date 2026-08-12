# Cài máy mới bằng NixOS — làm theo từng bước

Mục tiêu: cài NixOS, vào được Sway, có Wi-Fi, âm thanh, Chrome, VS Code,
Python và C/C++ trước. Chưa cần hiểu NixOS ở giai đoạn này.

> **Cảnh báo:** nếu chọn xóa ổ đĩa khi cài, Fedora và mọi dữ liệu trên ổ đó sẽ
> mất. Hãy backup trước khi bắt đầu.

## Phần A — chuẩn bị khi còn ở Fedora

### 1. Sao lưu dữ liệu quan trọng

Chép ra ổ cứng ngoài hoặc cloud những thứ cần giữ: Documents, Downloads, ảnh,
SSH key, mã 2FA, password manager và bookmark/profile trình duyệt nếu cần.

### 2. Đưa thư mục này thành repo GitHub riêng

Trong terminal Fedora, chạy:

```bash
cd ~/dotfiles
cp -a nixos ~/nix-config
cd ~/nix-config
git init
git add .
git commit -m "Initial NixOS laptop configuration"
```

Trên GitHub, tạo một repository mới tên `nix-config`, **không** chọn tạo README
hay `.gitignore`. Sau đó GitHub sẽ hiện các lệnh push. Chạy các lệnh đó trong
`~/nix-config`.

Ví dụ, nếu GitHub hiện URL của bạn là `https://github.com/USERNAME/nix-config.git`:

```bash
git branch -M main
git remote add origin https://github.com/USERNAME/nix-config.git
git push -u origin main
```

### 3. Tạo USB cài NixOS

1. Tải bản **NixOS GNOME ISO** từ [nixos.org/download](https://nixos.org/download/).
2. Cắm USB trống, dung lượng tối thiểu 8 GB. Dữ liệu trên USB sẽ bị xóa.
3. Mở Fedora Media Writer hoặc Balena Etcher.
4. Chọn file ISO vừa tải, chọn đúng USB, rồi bấm Flash/Write.
5. Đợi hoàn tất và rút USB an toàn.

## Phần B — cài NixOS từ USB

### 4. Boot vào USB

1. Tắt máy hoàn toàn.
2. Cắm USB cài NixOS.
3. Bật máy và nhấn liên tục một trong các phím `F12`, `Esc`, `F9` hoặc `F2`.
   Mỗi hãng máy khác nhau; đây là Boot Menu/BIOS Menu.
4. Chọn mục có tên USB và chữ `UEFI`.
5. Đợi desktop GNOME của USB hiện ra, rồi mở ứng dụng **Install NixOS**.

### 5. Cài bằng giao diện

Trong installer, cứ làm chậm và đọc từng màn hình:

1. Chọn ngôn ngữ, khu vực và bàn phím.
2. Kết nối Wi-Fi nếu installer yêu cầu.
3. Ở bước ổ đĩa:
   - Muốn thay Fedora hoàn toàn: chọn **Erase disk**.
   - Muốn giữ Fedora để dual boot: **dừng ở đây và hỏi trước**, vì partition
     sai có thể làm mất dữ liệu.
4. Tạo user có tên chính xác là:

   ```text
   doxuantuyen
   ```

   Đặt mật khẩu bạn nhớ được.
5. Bấm Install, chờ xong, rồi reboot. Rút USB khi máy bảo hoặc khi màn hình
   tắt trước lúc boot lại.

Sau reboot lần đầu, bạn sẽ vào GNOME. Đây là bình thường và chỉ là bước tạm.

## Phần C — biến máy mới thành desktop của bạn

### 6. Mở Terminal trong GNOME và chạy đúng các lệnh này

Đầu tiên, kết nối Wi-Fi. Mở Terminal rồi thay `USERNAME` trong lệnh đầu bằng
tên GitHub của bạn:

```bash
git clone https://github.com/USERNAME/nix-config.git ~/nix-config
cp /etc/nixos/hardware-configuration.nix ~/nix-config/hosts/laptop/
cd ~/nix-config
git add hosts/laptop/hardware-configuration.nix
sudo nixos-rebuild switch --flake .#laptop
```

Lệnh cuối sẽ tải và cài toàn bộ desktop. Lần đầu có thể mất từ vài phút đến lâu
hơn tùy mạng. **Đừng tắt máy khi lệnh đang chạy.**

Nếu lệnh báo lỗi, không tự sửa lung tung và chưa reboot: copy nguyên đoạn lỗi
gửi cho mình.

Khi lệnh hoàn tất không có lỗi, chạy:

```bash
reboot
```

### 7. Sau reboot: bạn đã vào máy mới

Màn đăng nhập chữ hiện ra. Nhập username `doxuantuyen`, password, rồi Enter.

Bạn sẽ vào Sway với thanh Waybar ở cạnh dưới.

| Việc cần làm | Phím / cách làm |
| --- | --- |
| Mở terminal Alacritty | `Super + Enter` |
| Mở menu app | `Super + D` |
| Mở Chrome | `Super + D`, gõ `Chrome` |
| Mở VS Code | `Super + D`, gõ `Visual Studio Code` |
| Mở quản lý file | `Super + D`, gõ `Thunar` |
| Khóa màn hình | `Super + Shift + O` |
| Chụp vùng và copy | `Print` |
| Điều chỉnh âm thanh/sáng màn | phím media của laptop |

Wi-Fi, Bluetooth, âm thanh, pin và giờ nằm trên Waybar. Nếu cần đổi âm lượng
chi tiết, mở `pavucontrol` bằng `Super + D`.

## Phần D — sau khi mọi thứ đã chạy

### 8. Lưu file phần cứng vào GitHub

Sau khi bạn đã vào Sway ổn định, mở Alacritty và chạy:

```bash
cd ~/nix-config
git add .
git commit -m "Add laptop hardware configuration and lock dependencies"
git push
```

Việc này giúp lần dựng lại sau có đúng driver/phân vùng và đúng phiên bản package.

### 9. Khi sau này sửa cấu hình Nix

Mỗi khi thay đổi file `.nix`, dùng:

```bash
cd ~/nix-config
sudo nixos-rebuild switch --flake .#laptop
```

Không chạy `setup.sh` của Fedora trên NixOS. Không dùng `sudo pip install`.
Với bài Python, dùng môi trường riêng trong project:

```bash
cd thu-muc-bai-python
python -m venv .venv
source .venv/bin/activate
```

## Nếu bị kẹt

- Không boot được USB: thử cổng USB khác; tắt Secure Boot nếu firmware của máy
  yêu cầu; kiểm tra USB đã được flash xong.
- Không thấy Wi-Fi ở GNOME installer: thử cắm Ethernet hoặc dùng USB tethering
  từ điện thoại; đừng xóa Fedora trước khi có cách vào mạng.
- `nixos-rebuild` báo lỗi: chụp/copy đầy đủ lỗi và hỏi, không tự chạy lệnh xóa
  hoặc copy từ Internet.
- Bản rebuild sau này làm desktop lỗi: chọn generation NixOS cũ trong menu boot.

Phần tổ chức repo (`hosts`, `modules`, `home`), flakes, dev shell và rollback
có thể học sau khi máy chạy ổn. Hiện tại chỉ cần làm đúng theo thứ tự ở trên.
