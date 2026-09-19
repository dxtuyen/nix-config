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

## TickTick — đã gỡ app desktop, dùng bản web

App desktop đã bị gỡ khỏi `home/packages.nix` (cộng đồng Nix đóng gói chậm:
bump mới nằm chờ ở nixpkgs-unstable, stable không được backport — không đáng
giữ gói unfree để rồi phải đeo input unstable). Dùng bản web thay thế:

- **Cách dùng**: `mod+d` → mở Chrome → ticktick.com. Muốn dạng cửa sổ riêng
  (không thanh địa chỉ, có icon riêng trong Rofi): trên ticktick.com → menu
  Chrome → *Cast, save and share → Install page as app* (PWA).
- **Không mất dữ liệu**: task nằm trên cloud TickTick, gỡ app không mất gì.
- **Mất gì**: thông báo đẩy nền (web chỉ báo khi mở tab, trừ khi bật Chrome
  notifications cho ticktick.com) — app desktop vốn cũng không có tray nên
  chênh lệch rất nhỏ.
- **Muốn cài lại**: thêm 1 dòng `ticktick` vào `home/packages.nix` + rebuild.

## Scripts quan trọng (`~/.local/bin`)

## Scripts quan trọng (`~/.local/bin`)

| Script | Chức năng |
|---|---|
| `power-menu` | Menu nguồn: Poweroff / Reboot / Suspend / **Hibernate** / Lock / Power Profile / Reload |
| `power-profile-menu` | Đổi battery-saver / balanced / performance |
| `quick-lang` | Trợ lý English cho văn bản đang bôi: VI/EN/trộn → English sạch, EN→VI, sửa lỗi ép (`fix`, dùng model mạnh hơn). Tag ngữ cảnh `[phi]`/`[sci]`/`[lit]`/`[cas]`/`[lĩnh vực]` đặt đầu văn bản. Gemini hết quota tự fallback Google Translate — key ở `~/.config/quick-lang/api.key` |
| `dict-toggle` | `mod+g`: bật/tắt GoldenDict float — đóng = ẩn về tray (tiến trình giữ nguyên, mở lại tức thời) |
| `lock-screen` | Khóa màn hình (swaylock), tự khóa khi idle 300s |
| `cycle-wallpaper` | Đổi hình nền sáng/tối theo giờ (06:00 / 18:00) |
| `refresh-session` | Reload Sway + wallpaper + wlsunset |
| `study` / `burst` / `pomodoro-menu` | 2 chế độ học song song: burst mặc định 10 phút (tự nhập 1–480) + phiên study thuần preset 60/90/120 hoặc tự nhập 1–480 (xem mục bên dưới) |
| `screenshot` / `screenshot-menu` | Chụp màn hình (vùng/toàn màn × clipboard/file) |

> Các phím tắt chi tiết được khai trong `home/sway.nix` — tra cứu tại đó khi cần.

## Focus — Burst & Study song song (`$mod+p`)

| Chế độ | Vai trò | Cách dùng |
|---|---|---|
| 🔥 `burst` | **Phiên siêu tập trung** — mặc định **10 phút** (tự nhập được 1–480), chạy song song | Menu → *🔥 Burst — mặc định 10 phút* hoặc *🔥 Burst — tự nhập số phút* |
| 📚 `study` | **Phiên học thuần** — preset **60/90/120** hoặc tự nhập **1–480 phút**, không break | Menu → chọn preset hoặc *📚 Study — tự nhập số phút* |

Menu rofi (`$mod+p`) — **KHÔNG có điều khiển chung**: mỗi dòng là 1 hành động trực tiếp cho chính đồng hồ đó. Rảnh hoàn toàn → 6 dòng khởi động:

```
🔥 Burst — mặc định 10 phút
🔥 Burst — tự nhập số phút (1–480)...
📚 Study — phiên học thuần 60 min
📚 Study — phiên học thuần 90 min
📚 Study — phiên học thuần 120 min
📚 Study — tự nhập số phút (1–480)...
```

Đang có phiên → mỗi đồng hồ hiện 2 dòng (toggle + Reset riêng):

```
⏸ Burst · còn 09:23    ← bấm để pause (khi pause: ▶ bấm để resume)
↺ Reset Burst
⏸ Study · còn 87:12
↺ Reset Study
```

- **Mỗi dòng tự giải thích**: rảnh → dòng khởi động; đang chạy → `⏸` bấm để pause; tạm dừng → `▶` bấm để resume; `↺ Reset` chỉ xoá đồng hồ của chính nó và chỉ hiện khi đồng hồ đó có phiên. Muốn đổi mốc → Reset rồi chọn lại.
- 2 đồng hồ **độc lập hoàn toàn**: start/pause/reset một bên không cản trở bên kia — burst có thể bật giữa chừng phiên study.
- **Tự phục hồi**: daemon chết giữa chừng → lần mở menu tiếp theo (hoặc waybar refresh) tự finalize phiên đã hết hạn (chuông/thông báo/lịch sử) hoặc hồi sinh daemon — không bao giờ kẹt đồng hồ "còn 00:00".
- Hết giờ: chuông + thông báo. Lịch sử phiên học ghi tại `~/.local/state/pomodoro-history.log` (mỗi dòng: thời điểm · nhãn · số phút).

```bash
burst start        # 10 phút mặc định (song song với study)
burst start 25     # burst tự nhập 25 phút (1–480)
study start 90     # phiên học thuần 90 phút (preset)
study start 45     # phiên học thuần tự nhập 45 phút (1–480)
study toggle       # pause/resume study (burst: burst toggle)
```

## Khóa màn hình • Idle • Sleep (swayidle)

| Sau | Hành động |
|---|---|
| 300s idle | khóa màn hình (`lock-screen`) |
| 310s idle | tắt màn — có thao tác → bật lại nhưng vẫn khóa |
| 900s idle | suspend (ngủ) — **chỉ khi đang dùng pin**; cắm sạc → thức tiếp (màn vẫn tắt & khóa) nhưng watcher nền chờ sẵn: **rút sạc khi vẫn idle → tự ngủ sau tối đa ~30s**; **bỏ qua khi Study/Burst đang chạy** |
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
