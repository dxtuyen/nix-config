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
| `wallpaper-set` | `Alt+Tab`: đổi nền random qua **awww** (fork của swww, transition fade 1.5s). **Luôn loại ảnh đang hiển thị** → bấm liên tục luôn ra ảnh mới. Lúc đăng nhập: **giữ nguyên ảnh phiên trước** (chưa có ảnh → random 1 ảnh). Ảnh ở `~/Pictures/wallpapers` — xem mục [Ảnh nền](#ảnh-nền-wallpaper) để thêm ảnh |
| `wallpaper-menu` | `Alt+Shift+Tab`: menu rofi **hiện thumbnail** dạng lưới 3 cột × 3 hàng — ảnh trên, tên file dưới (dài quá tự cắt `…`), ảnh đang dùng đánh dấu `●`; xếp lấp từ trái sang phải (đủ 3 mới xuống hàng), quá 9 ảnh giữ 3 hàng và cuộn (thanh bên phải) |
| `refresh-session` | Reload Sway + wlsunset (nền giữ nguyên — daemon awww vẫn hiển thị) |
| `study` / `pomodoro-menu` / `focus-sleep-watch` | Đồng hồ PHIÊN TẬP TRUNG duy nhất: rảnh → ⌨ tự nhập 1–480 / 🍅 30/60/120; có phiên → chỉ ⏸/▶ + ↺; phiên chạy → tự dừng swayidle (chống khóa/tắt màn/ngủ); ngủ → tự pause, dậy → tự tiếp tục (xem mục bên dưới) |
| `screenshot` / `screenshot-menu` | Chụp màn hình (vùng/toàn màn × clipboard/file) |

> Các phím tắt chi tiết được khai trong `home/sway.nix` — tra cứu tại đó khi cần.

## Ảnh nền (wallpaper)

**Không có logic theo giờ, không chia pool:** mọi ảnh trong `~/Pictures/wallpapers/` đều random như nhau. Ảnh màn hình khoá nằm riêng ở `lockscreen/` của repo — nằm ngoài `wallpapers/` nên không bao giờ lẫn vào vòng xoay.

- **Mỗi lần đăng nhập**: giữ nguyên ảnh của phiên trước (daemon awww tự khôi phục từ cache `~/.cache/awww`) — nếu chưa có ảnh (máy mới / cache trống) mới tự random 1 ảnh
- **Đổi ảnh bất cứ lúc nào**: `Alt+Tab` (random — luôn khác ảnh đang dùng) hoặc `Alt+Shift+Tab` (menu rofi lưới thumbnail 3×3, tên dưới ảnh, xếp lấp trái→phải, `●` là ảnh đang dùng; >9 ảnh tự cuộn)

**Thao tác nhanh — chọn nhanh đường đi:**

| Muốn | Cách làm | Rebuild? |
|---|---|---|
| Thêm ảnh bền vững | `cp` vào `~/nix-config/wallpapers/` + `git add` | ✅ Có |
| Thêm ảnh dùng tạm | `cp` vào `~/Pictures/wallpapers/` | ❌ Không |
| Xóa ảnh | xóa đúng nơi nó nằm (repo → `git rm`; copy tay → `rm`) | Chỉ ảnh repo |
| Thay ảnh cùng tên | ghi đè file trong **repo** (repo là file thật, ghi được) | ✅ Có |
| Đổi tên ảnh | `git mv` trong repo | ✅ Có |

### Thêm ảnh — chỉ cần bỏ file vào repo (khuyên dùng)

1. Copy ảnh vào thư mục `wallpapers/` của repo:
   ```bash
   cp ~/Downloads/hinh-moi.jpg ~/nix-config/wallpapers/hinh-moi.jpg
   ```
2. `git add wallpapers/` — **bắt buộc**, vì flake chỉ nhìn thấy file đã được git theo dõi
3. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake ~/nix-config#laptop
   ```

Không phải sửa file `.nix` nào — `home/scripts.nix` **tự quét** thư mục `wallpapers/`. Sang máy mới chỉ cần clone repo là có đủ ảnh.

> ⚠️ **Trùng tên**: các ảnh trong repo được symlink vào `/nix/store` (chỉ đọc). Nếu copy file vào `~/Pictures/wallpapers/` mà **trùng tên** với ảnh đã có từ repo, `cp` sẽ ghi vào symlink và báo `Permission denied`. Lúc đó hãy thêm ảnh qua repo (bước ở trên) rồi rebuild — không copy đè trực tiếp. (Trùng tên với ảnh copy tay bình thường thì ghi đè được.)

### Thêm nhanh, không cần rebuild

Copy thẳng vào `~/Pictures/wallpapers/` và dùng ngay (nhược điểm: không nằm trong repo nên mất khi cài lại máy):

```bash
cp ~/Downloads/hinh-moi.jpg ~/Pictures/wallpapers/hinh-moi.jpg
```

### Xóa ảnh

**Ảnh copy tay** (file thường trong `~/Pictures/wallpapers/`) — xóa là xong, không rebuild:

```bash
rm ~/Pictures/wallpapers/ten-anh.jpg
```

**Ảnh nằm trong repo** — `git rm` rồi rebuild, home-manager tự gỡ symlink tương ứng khỏi `~/Pictures/wallpapers/`:

```bash
cd ~/nix-config
git rm wallpapers/ten-anh.jpg
sudo nixos-rebuild switch --flake ~/nix-config#laptop
```

💡 Nếu xóa đúng ảnh **đang hiển thị**: bấm `Alt+Tab` đổi sang ảnh khác *trước*. (Hệ thống vẫn tự phục hồi — daemon giữ ảnh trong bộ nhớ, lần đăng nhập sau cache trỏ file mất thì `wallpaper-set --if-empty` tự rơi về random — nhưng đổi trước vẫn gọn hơn.)

### Thay thế / đổi tên ảnh

**Thay bản đẹp hơn, giữ nguyên tên** — ghi đè trong thư mục **repo** (file ở đó là file thật, ghi được; symlink read-only chỉ có ở `~/Pictures/wallpapers/`):

```bash
cp -f ~/Downloads/anh-dep-hon.jpg ~/nix-config/wallpapers/ten-cu.jpg
cd ~/nix-config && git add wallpapers/
sudo nixos-rebuild switch --flake ~/nix-config#laptop
```

**Đổi tên** (script không theo quy ước tên nào — tự do đặt lại, ảnh vẫn random như thường):

```bash
cd ~/nix-config
git mv wallpapers/cu.jpg wallpapers/moi.jpg
sudo nixos-rebuild switch --flake ~/nix-config#laptop
```

**Ảnh màn hình khoá**: thay đúng file `lockscreen/nixos.jpg` (tên cố định, được chèn thẳng vào script `lock-screen`) rồi rebuild.

> ⚠️ Git giữ mọi phiên bản cũ của file binary → thay cùng tên nhiều lần làm lịch sử repo phình dần (hiện mới ~13MB nên không sao). Giữ ranh giới: **bộ ảnh ít đổi → commit vào repo; bộ hay thay → thả thẳng `~/Pictures/wallpapers/` không commit.**

### Lệnh tay

| Lệnh | Việc |
|---|---|
| `~/.local/bin/wallpaper-set` | Đổi sang ảnh random khác |
| `~/.local/bin/wallpaper-set <đường-dẫn-ảnh>` | Đặt đúng ảnh chỉ định |
| `~/.local/bin/wallpaper-menu` | Mở menu chọn ảnh lưới 3×3 (như `Alt+Shift+Tab`) |
| `awww query` | Xem ảnh đang hiển thị |
| `ls ~/Pictures/wallpapers/` | Danh sách ảnh thực tế (kiểm tra sau thêm/xóa) |
| `git -C ~/nix-config status` | Đã stage đủ ảnh trước khi rebuild |

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
| Wallpaper không đổi | `systemctl --user status awww-daemon` (daemon giữ ảnh nền); test tay: `~/.local/bin/wallpaper-set`. Script tự loại ảnh đang hiển thị nên bấm Alt+Tab luôn ra ảnh mới; menu Alt+Shift+Tab hiện lưới thumbnail 3×3, tên dưới ảnh (ảnh đang dùng có dấu `●`) |
| Hibernate không dậy | `cat /proc/cmdline` phải có `resume=UUID=...`; `swapon --show` phải thấy `/dev/nvme0n1p3` |

## Liên quan

- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — hệ thống có những gì
- [03-Cai-May-Moi](03-Cai-May-Moi.md) — khi máy hỏng nặng / máy mới
- [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md) — backup trước khi rủi ro
