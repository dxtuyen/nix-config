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
| `study` / `pomodoro-menu` / `focus-sleep-watch` | Đồng hồ PHIÊN TẬP TRUNG duy nhất: rảnh → ⌨ tự nhập 1–480 / 🍅 30/60/120; có phiên → chỉ ⏸/▶ + ↺; phiên chạy → tự dừng swayidle (chống khóa/tắt màn/ngủ); ngủ → tự pause, dậy → tự tiếp tục (xem mục bên dưới) |
| `screenshot` / `screenshot-menu` | Chụp màn hình (vùng/toàn màn × clipboard/file) |

> Các phím tắt chi tiết được khai trong `home/sway.nix` — tra cứu tại đó khi cần.

## Focus — đồng hồ PHIÊN TẬP TRUNG duy nhất (`$mod+p`)

Chỉ MỘT chế độ, KHÔNG break. Rảnh hoàn toàn → menu khởi động:

```
⌨ Minutes (1–480)...
🍅 30
🍅 60
🍅 120
```

Đang có phiên (đang chạy hoặc tạm dừng) → menu chỉ còn ĐÚNG 2 dòng:

```
⏸ 87:12    ← bấm để pause (khi pause: ▶ bấm để resume)
↺ Reset
```

- **Mỗi dòng tự giải thích**: rảnh → dòng khởi động; có phiên → menu ẩn preset, chỉ còn `⏸`/`▶` toggle + `↺ Reset`. Muốn đổi mốc → `↺ Reset` rồi mở lại menu.
- **Không mất lịch sử**: đổi phiên giữa chừng bằng CLI (`study start …`) vẫn ghi phần đã tập trung ≥ 1 phút vào lịch sử.
- **Tự động chống idle** (giống bật nút idle_inhibitor trên Waybar): phiên đang chạy → swayidle tạm dừng — **không khóa màn 300s, không tắt màn 310s, không ngủ 900s**; pause / reset / hết giờ → swayidle tự bật lại, mọi thứ về như bình thường. (Đóng nắp laptop vẫn ngủ như cũ.)
- **Icon chống idle trên bar là NÚT ĐỘC LẬP** (như idle_inhibitor cũ), đồng bộ với phiên: phiên chạy → mắt mở **xanh** (tự động); bấm tay → mắt mở **vàng** (thủ công, giữ cả khi không có phiên); không nguồn nào → mắt gạch mờ (màn hình khóa/tắt/ngủ bình thường). **Bấm icon = bật/tắt chống idle thủ công**; tắt tay khi phiên đang chạy sẽ chỉ có hiệu lực sau khi phiên dừng (thông báo sẽ nhắc).
- **Đóng nắp / máy ngủ → phiên tự TẠM DỪNG** (`focus-sleep-watch` nghe tín hiệu logind): REMAINING được tính lại đúng trước khi ngủ nên **thời gian ngủ không bị trừ vào phiên**; thức dậy → swayidle tự bật lại, phiên tự tiếp tục ▶ (hoặc finalize nếu phiên hết trong lúc ngủ). Muốn dừng hẳn thì `↺ Reset` sau khi dậy.
- **Tự phục hồi**: daemon chết giữa chừng → lần mở menu tiếp theo (hoặc waybar refresh) tự finalize phiên đã hết hạn (chuông/thông báo/lịch sử) hoặc hồi sinh daemon — không bao giờ kẹt đồng hồ "còn 00:00".
- Hết giờ: chuông + thông báo. Lịch sử phiên ghi tại `~/.local/state/pomodoro-history.log` (mỗi dòng: thời điểm · `focus` · số phút).

```bash
study start 30     # preset 🍅 30
study start 45     # tự nhập 45 phút (1–480)
study toggle       # pause/resume
```

## Khóa màn hình • Idle • Sleep (swayidle)

| Sau | Hành động |
|---|---|
| 300s idle | khóa màn hình (`lock-screen`) |
| 310s idle | tắt màn — có thao tác → bật lại nhưng vẫn khóa |
| 900s idle | suspend (ngủ) — **chỉ khi đang dùng pin**; cắm sạc → thức tiếp (màn vẫn tắt & khóa) nhưng watcher nền chờ sẵn: **rút sạc khi vẫn idle → tự ngủ sau tối đa ~30s**; **bỏ qua khi phiên Focus đang chạy** (phiên chạy → cả chuỗi 300s/310s/900s tạm dừng, pause/reset/hết giờ → tự bật lại) |
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
