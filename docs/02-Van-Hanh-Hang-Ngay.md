# 02 — Vận hành hằng ngày

## Áp dụng thay đổi (rebuild)

```bash
cd ~/nix-config
git pull --rebase                              # lấy code mới nhất
nix fmt                                        # format *.nix (nixfmt)
sudo nixos-rebuild switch --flake .#laptop    # hoặc: nh os switch
```

- Sửa file `.nix` xong **bắt buộc rebuild** mới có tác dụng.
- Mỗi rebuild tạo 1 **generation** — luôn quay lại được bản cũ (chọn ở menu boot khi khởi động).

## Các lệnh hay dùng

| Việc | Lệnh |
|---|---|
| Cập nhật nixpkgs / home-manager | `nix flake update` |
| List các generation | `nixos-rebuild list-generations` |
| Quay lại generation cũ | `nixos-rebuild switch --rollback` |
| Dọn rác store | `nix-collect-garbage -d` (GC tự động hàng tuần theo `core.nix`) |
| Xem log Sway | `journalctl -b -u sway` / `journalctl --user -u sway` |

## Gói lấy từ nixpkgs-unstable

Một số app cần bản mới hơn bản đóng gói trong nhánh stable — ví dụ **TickTick**
phát hành bản chính thức sớm, còn gói `ticktick` trong `nixos-26.05` chậm vài
phiên bản. Vì vậy `ticktick` được lấy riêng từ input `nixpkgs-unstable`
(khai trong `flake.nix`, cấu hình ở `home/packages.nix`); các gói khác vẫn
dùng stable. Để nâng gói này lên bản mới nhất trên unstable:

```bash
nix flake update nixpkgs-unstable   # cập nhật riêng input unstable
sudo nixos-rebuild switch --flake .#laptop
```

(Có thể bỏ qua bước *update* nếu chưa muốn: cứ rebuild là dùng đúng bản
đã lock trong `flake.lock`.)

## Scripts quan trọng (`~/.local/bin`)

| Script | Chức năng |
|---|---|
| `power-menu` | Menu nguồn: Poweroff / Reboot / Suspend / **Hibernate** / Lock / Power Profile / Reload |
| `power-profile-menu` | Đổi battery-saver / balanced / performance |
| `quick-lang` | Dịch văn bản đang bôi (VI↔EN) bằng Gemini — key ở `~/.config/quick-lang/api.key` |
| `lock-screen` | Khóa màn hình (swaylock), tự khóa khi idle 300s |
| `cycle-wallpaper` | Đổi hình nền sáng/tối theo giờ (06:00 / 18:00) |
| `refresh-session` | Reload Sway + wallpaper + wlsunset |
| `pomodoro` / `pomodoro-menu` | Timer học tập + menu |
| `screenshot` / `screenshot-menu` | Chụp màn hình (vùng/toàn màn × clipboard/file) |

> Các phím tắt chi tiết được khai trong `home/sway.nix` — tra cứu tại đó khi cần.

## Khóa màn hình • Idle • Sleep (swayidle)

| Sau | Hành động |
|---|---|
| 300s idle | khóa màn hình (`lock-screen`) |
| 310s idle | tắt màn — có thao tác → bật lại nhưng vẫn khóa |
| 900s idle | suspend (ngủ) — màn đã khóa nên an toàn |
| before-sleep | luôn khóa lại trước khi ngủ |
| lock / unlock | logind khóa → khóa ngay; unlock → bật màn |

## Chế độ ngủ: deep (S3) vs s2idle

Config đặt `mem_sleep_default=deep` trong `boot.kernelParams` của
`modules/nixos/laptop.nix` — nghĩa là mọi lần ngủ (đóng nắp laptop, idle 900s,
`power-menu` → Suspend) máy rơi vào **deep sleep (S3)** thay vì `s2idle`
(modern standby) → **tốn ít pin hơn đáng kể** khi ngủ.

Kiểm tra máy đang ngủ bằng chế độ nào:

```bash
cat /sys/power/mem_sleep
```

- `s2idle [deep]` → đang dùng **deep** (dấu ngoặc vuông = chế độ mặc định). ✓
- `[s2idle]` → máy không hỗ trợ S3, tự rơi về s2idle. Tham số
  `mem_sleep_default=deep` khi đó **bị kernel bỏ qua, vô hại** — có thể giữ
  nguyên hoặc xóa dòng đó trong `modules/nixos/laptop.nix` cho gọn rồi rebuild.

> Lưu ý: tham số này chỉ hiệu lực sau khi **khởi động lại** (nó là tham số
> kernel), rebuild + reboot một lần là áp dụng.

## Hibernate

Cách dùng: chạy `systemctl hibernate` (hoặc dùng menu nguồn `power-menu`) — máy nén toàn bộ RAM vào **swap 10G**, tắt nguồn; khi bật lại khôi phục nguyên trạng.

Điều kiện hoạt động (đã cấu hình sẵn):
- Phân vùng swap **≥ RAM**: máy này 10G ≥ 7.4G ✓. Swap khai trong `hosts/laptop/hardware-configuration.nix` (file tự sinh).
- Kernel có tham số `resume=UUID=...` (trong `modules/nixos/laptop.nix`) để biết swap nào chứa image khôi phục.

## Sự cố thường gặp

| Triệu chứng | Kiểm tra |
|---|---|
| Sway không khởi động | `journalctl -b -u greetd` |
| Mất âm thanh | `systemctl status pipewire` → `systemctl --user restart wireplumber` |
| Bộ gõ kẹt | `fcitx5-diagnose` |
| Wallpaper sai giờ | `systemctl --user status cycle-wallpaper.timer` |
| Hibernate không dậy | `cat /proc/cmdline` phải có `resume=UUID=...`; `swapon --show` phải thấy `/dev/nvme0n1p3` |

## Liên quan

- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — hệ thống có những gì
- [03-Cai-May-Moi](03-Cai-May-Moi.md) — khi máy hỏng nặng / máy mới
- [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md) — backup trước khi rủi ro
