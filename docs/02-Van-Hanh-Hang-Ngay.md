# 02 — Vận hành hằng ngày

> Triết lý vận hành của repo này học theo thread
> [Tips & Tricks for NixOS Desktop của matklad](https://discourse.nixos.org/t/tips-tricks-for-nixos-desktop/28488):
> dùng **unstable** cho desktop, tìm **option** trước package,
> không `nix-env`, và hỏng thì **boot vào generation ngon** thay vì rollback mù.

## 1. Use NixOS-unstable

Hệ thống chạy **nixos-unstable** (`flake.nix` → `nixpkgs.url = .../nixos-unstable`).
"Unstable" là misnomer — thực chất là rolling release được gate bởi test suite,
khá ổn định, app luôn mới (yazi có Trash bin, foliate/chrome/vscode mới...).
Lỡ hỏng thì boot generation cũ ở menu systemd-boot là xong
(`configurationLimit = 10` trong `modules/nixos/core.nix` luôn giữ bản ngon).

## 2. Đừng rollback — hãy boot vào bản ngon rồi ghim nó

Khi config hỏng, **đừng** đứng ở bản hỏng rồi đoán lùi mấy đời:

```bash
# ❌ KHÔNG làm thế này khi đang ở config hỏng:
nixos-rebuild switch --rollback
```

Làm theo matklad — boot vào generation đang chạy tốt (chọn ở menu systemd-boot
lúc khởi động), rồi ghim nó thành mặc định:

```bash
/run/current-system/bin/switch-to-configuration boot
```

Xong — lần boot sau máy vào thẳng bản ngon, không cần đếm generation.

> ⚠️ 2 caveat từ chính thread (post #5 bjornfor + #6 matklad, #9 Nebucatnetzer):
> - `switch-to-configuration boot` chạy standalone **không luôn tạo boot entry đúng** ([issue #82851](https://github.com/NixOS/nixpkgs/issues/82851)). matklad confirm **trên systemd-boot thì work** (repo này dùng systemd-boot nên đúng đường), còn GRUB có thể khác (có người mất generations trên GRUB).
> - Boot bản ngon **không rollback state** (VD app dùng database đã migrate) — chỉ rollback hệ thống + config.

```bash
nixos-rebuild list-generations   # xem các bản còn giữ
```

## 3. Tìm package ở search.nixos.org, tìm option trước package

- Tìm gói: [search.nixos.org/packages](https://search.nixos.org/packages) —
  nhanh và chuẩn hơn `nox` hay mò trên CLI. Trên máy thì `nix search nixpkgs <tên>`
  (kể cả flake khác) hoặc vào `nix repl` rồi `:load-flake` để mò attr path.
- Việc gì cũng **tìm option trước** (`search.nixos.org/options`): docker/emacs/
  sway/thunar... có option riêng kèm systemd daemon + tích hợp hệ thống,
  ngon hơn cài package trần. Repo này đã theo hướng đó
  (`programs.sway/thunar`, `services.pipewire/gvfs`, `i18n.inputMethod.fcitx5`...).
  Dev lib để per-project (`nix develop` + `direnv`, xem `home/default.nix`).

## 4. Không dùng nix-env — mọi gói đều khai báo trong repo

- Cần thử 1 lần: `nix shell nixpkgs#ffmpeg` (dùng xong vứt, không để lại rác).
- Cần quá 2 lần: thêm vào `home/packages.nix` (gói user) hoặc
  `environment.systemPackages` (gói hệ thống) rồi rebuild.
- Home-Manager ở đây quản lý **dotfiles** (sway/foot/waybar/mimeapps/scripts...),
  không phải chỉ để cài package user — nên giữ, đừng dồn hết lên system.
  (matklad ngại HM vì ông ấy single-user không cần package user-specific, dotfiles
  ông ấy symlink tay bằng script `xtool` — post #3/#4. Repo này chọn HM vì nó còn
  lo systemd user service, xdg/mime/gtk/dconf và `${pkgs...}` chèn vào script,
  những việc symlink tay không làm được.)

## 5. Chạy binary ngoài: nix-ld (canonical) + distrobox + appimage-run

Thay cho `buildFHSUserEnv` thủ công thời 2023, repo dùng stack hiện đại.
`nix-ld` là giải pháp **canonical** hiện nay (bittner 2024), kèm `steam-run` /
`nix-alien` cho việc nhanh-gọn:

| Việc | Công cụ (đã khai sẵn) |
|---|---|
| Binary biên dịch sẵn (VS Code server, JetBrains...) chạy không cần patch | `programs.nix-ld` (`modules/nixos/system-tweaks.nix`) |
| Chạy nhanh 1 lệnh không cần setup | `steam-run ./binary` |
| Môi trường Fedora/Ubuntu | `distrobox` + `podman` (`home/packages.nix`, `modules/nixos/development.nix`) |
| AppImage (RemNote) | `appimage-run` + script `setup-remnote` (`home/remnote.nix`) |

Chỉ dựng FHS custom khi gặp đúng 1 binary closed-source cứng đầu
không chạy được qua 4 đường trên.

## 6. Vá nóng unstable: cherry-pick PR chưa merge (matklad #14)

Sống trên unstable thì thỉnh thoảng có gói vỡ đã có PR sửa nhưng chưa merge.
Thay vì chờ, cherry-pick thẳng diff vào nixpkgs của mình bằng `applyPatches`:

```nix
# flake.nix — mẫu, KHÔNG bật sẵn. Khi cần thì copy vào `outputs`:
# 1. Thêm patch (chưa biết hash thì điền dummy, đọc hash từ lỗi rồi sửa).
# 2. Khi PR được merge vào unstable, patch apply fail → biết để xóa.
let
  patches = [
    {
      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/292148.diff";
      sha256 = "sha256-gaH4UxKi2s7auoaTmbBwo0t4HuT7MwBuNvC/z2vvugE=";
    }
  ];
  originPkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  patchedNixpkgs = originPkgs.applyPatches {
    name = "nixpkgs-patched";
    src = inputs.nixpkgs;
    patches = map originPkgs.fetchpatch patches;
  };
  nixosSystem = import (patchedNixpkgs + "/nixos/lib/eval-config.nix");
in
{
  # nixosConfigurations.laptop = nixosSystem { ... };
}
```

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
| Cập nhật nixpkgs-unstable / home-manager | `nix flake update` |
| List các generation | `nixos-rebuild list-generations` |
| Quay lại bản ngon (đang boot ở bản ngon) | `/run/current-system/bin/switch-to-configuration boot` |
| Dọn rác store | `nix-collect-garbage -d` (GC tự động hàng tuần theo `core.nix`) |
| Dọn generation cũ + đánh số lại **về 1** | `sudo bash scripts/reset-generations.sh` — xem [Đánh số lại generation](#đánh-số-lại-generation-về-1) |
| Xem log Sway | `journalctl -b -u sway` / `journalctl --user -u sway` |
| Tìm file / tìm trong nội dung | `fd -e pdf` · `rg -g '*.md' 'từ_khoá'` (thay `find`/`grep`) |

## Đánh số lại generation về 1

Xoá generation cũ **không** làm số nhỏ đi: nix đánh số mới = *số lớn nhất còn lại*
+ 1 (`system-1`..`system-17` xoá hết, chỉ còn `system-18-link` → bản mới vẫn là 19).
Muốn profile về đúng **generation 1** (để rebuild sau đó là 2, 3...) thì phải
**đổi tên link** — script `scripts/reset-generations.sh` làm hết trong 1 lần chạy:

```bash
sudo bash scripts/reset-generations.sh          # flake = thư mục repo, host = laptop
# hoặc chỉ định: sudo bash scripts/reset-generations.sh /đường/dẫn/flake tên-host
```

Nó chạy 4 bước: **(1)** xoá mọi generation trừ bản đang chạy
(`nix-env -p /nix/var/nix/profiles/system --delete-generations old`) → **(2)**
`mv system-<N>-link system-1-link` + sửa symlink `system` trỏ vào nó → **(3)**
`nixos-rebuild switch` (tạo generation 2, đồng thời ghi lại boot entry) → **(4)**
`nix-collect-garbage -d`.

**Vì sao có bước rebuild:** builder systemd-boot **xoá sạch mọi entry `nixos*`**
trong `/boot/loader/entries` rồi ghi lại theo danh sách generation hiện có ⇒ entry
của generation đã xoá tự được dọn, không cần xoá tay.

> ⚠️ Sau khi chạy **không rollback được về các bản cũ** (đã xoá vĩnh viễn).

**2 chốt an toàn script tự kiểm** (đừng bỏ qua):

1. **`/boot` phải đang mount** — không thì bước 3 chết đúng ở
   `Failed to install bootloader` (đã từng xảy ra khi `/etc/fstab` còn UUID của
   máy khác). Kiểm: `mountpoint -q /boot && echo ok`.
2. **Không bao giờ để 0 generation** — builder systemd-boot từ chối chạy khi
   danh sách generation rỗng ("refusing to remove all boot loader entries") vì sẽ
   xoá sạch kernel/initrd trên ESP → máy không boot được. Script luôn giữ lại bản
   đang chạy.

**Lưới an toàn còn lại:** generation 1 (bản đang chạy) + `boot.loader.systemd-boot.configurationLimit = 10`
(menu boot giữ tối đa 10 entry) + GC tự động hàng tuần với `--delete-older-than 7d`
(`core.nix`) tự dọn generation cũ hơn 7 ngày.

## Scripts quan trọng (`~/.local/bin`)

| Script | Chức năng |
|---|---|
| `power-menu` | Menu nguồn: Poweroff / Reboot / Suspend / **Hibernate** / Lock / Power Profile / Reload |
| `power-profile-menu` | Đổi battery-saver / balanced / performance |
| `quick-lang` | Trợ lý English cho văn bản đang bôi: VI/EN/trộn → English sạch, EN→VI, sửa lỗi ép (`fix`, dùng model mạnh hơn). Tag ngữ cảnh `[phi]`/`[sci]`/`[lit]`/`[cas]`/`[lĩnh vực]` đặt đầu văn bản. Gemini hết quota tự fallback Google Translate — key ở `~/.config/quick-lang/api.key` |
| `dict-toggle` | `mod+g`: bật/tắt GoldenDict float — đóng = ẩn về tray (tiến trình giữ nguyên, mở lại tức thời) |
| `lock-screen` | Khóa màn hình (swaylock), tự khóa khi idle 300s |
| `wallpaper-set` | `$mod+r`: đổi nền random qua **awww** (fork của swww, transition fade 1.5s). **Luôn loại ảnh đang hiển thị** → bấm liên tục luôn ra ảnh mới. Lúc đăng nhập: **giữ nguyên ảnh phiên trước** (chưa có ảnh → random 1 ảnh). ⛔ Auto-rotate 30 phút **đã TẮT** (xem mục [Tự đổi ảnh nền mỗi 30 phút](#tự-đổi-ảnh-nền-mỗi-30-phút-auto-rotate)). Ảnh ở `~/Pictures/wallpapers` — xem mục [Ảnh nền](#ảnh-nền-wallpaper) để thêm ảnh |
| `wallpaper-menu` | `$mod+Shift+r`: menu rofi **lưới 3×3 thumbnail 320px** (ảnh trên, tên dưới, đang dùng đánh dấu `●`, >9 ảnh tự cuộn) — icon lấy từ **cache** `~/.cache/wallpaper-thumbs/` + build list **0 spawn** (đo: 2.2s → 0.05s với 333 ảnh) → **mở tức thì**. Lần đầu / vừa thêm ảnh: mở **dựng cache nền** → lần sau tự lưới. Chế độ: `--grid` (ép lưới), `--list` (chữ thuần, nhanh nhất)<br>**Phím duyệt ảnh:** `←` `→` **sang cột** · `↑` `↓` lên/xuống hàng · `Tab`/`Shift+Tab` hàng trước/sau · `Page_Up`/`Page_Down` trang trước/sau · `Home`/`End` ảnh đầu/cuối · lưới hết cuối **vòng lại đầu** (`cycle`). Bản `Alt+` tương ứng cho bàn phím không có phím mũi tên: `Alt+h/j/k/l`, `Alt+u/i/o/p`<br>**Đã sửa lỗi "dính chùng điều hướng với con trỏ gõ chữ":** rofi mặc định gán `Left`/`Right` cho **con trỏ trong ô filter**, còn `Ctrl+Page_Up/Down` mới sang cột → **không bao giờ sang được cột 2, 3** của lưới (với `keyd` còn tệ hơn: `Ctrl` phải bấm qua `CapsLock`, dễ lỡ tay thành `Esc` là đóng mất menu). Menu này **đổi chỗ** — `←`/`→` sang cột, con trỏ gõ chuyển sang `Alt+←`/`Alt+→` (vẫn đủ `Alt+b/f`, `Ctrl+←/→`, `Ctrl+a/e`, `BackSpace`) nên **không mất phím nào**. Chỉ áp cho menu này, không đụng `rofi -show drun/window` |
| `wallpaper-thumbs` | Dựng thumbnail 320px cho menu (song song 8 luồng, ImageMagick, đếm thiếu bằng builtin không fork). Chạy nền khi menu cần; `--status` chỉ còn để tra tay. Xoá `~/.cache/wallpaper-thumbs/` bất cứ lúc nào → tự dựng lại |
| `refresh-session` | Reload Sway + wlsunset (nền giữ nguyên — daemon awww vẫn hiển thị) |
| `yazi` | `$mod+y`: file manager trong terminal, mở dạng **popup** nhỏ ở thư mục hiện tại (gõ `yazi` trong terminal thì ra cửa sổ thường, xem trước ảnh đẹp hơn). `<Enter>` tự rẽ nhánh: thư mục thì vào, file thì mở app · `d` xoá vào thùng rác · `g` `t` menu thùng rác (xem [Thùng rác](#thùng-rác-tự-động-dọn-lúc-0300)). Thunar vẫn dùng được cho việc khác |
| `study` / `pomodoro-menu` / `focus-sleep-watch` | Đồng hồ PHIÊN TẬP TRUNG duy nhất: rảnh → ⌨ tự nhập 1–480 / 🍅 30/60/120; có phiên → chỉ ⏸/▶ + ↺; phiên chạy → tự dừng swayidle (chống khóa/tắt màn/ngủ); ngủ → tự pause, dậy → tự tiếp tục (xem mục bên dưới) |
| `screenshot` / `screenshot-menu` | Chụp màn hình (vùng/toàn màn × clipboard/file) |

> Các phím tắt chi tiết được khai trong `home/sway.nix` — tra cứu tại đó khi cần.

## Ảnh nền (wallpaper)

**Không có logic theo giờ, không chia pool:** mọi ảnh trong `~/Pictures/wallpapers/` đều random như nhau.

> 📁 **Ảnh nền nằm NGOÀI repo.** Thư mục `~/Pictures/wallpapers/` do bạn tự quản lý — `cp`/`rm` thoải mái, **không rebuild, không commit, không ai ghi đè**. Repo chỉ giữ đúng **một** file ảnh: `lockscreen/nixos.jpg` (ảnh khoá màn hình, tên cố định, chèn thẳng vào script `lock-screen`).
>
> Hệ quả: **cài máy mới phải copy ảnh vào `~/Pictures/wallpapers/`** (xem [03-Cai-May-Moi](03-Cai-May-Moi.md)), và **backup `~/Pictures` là bắt buộc** — nó là bản duy nhất (xem [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md)).

- **Mỗi lần đăng nhập**: giữ nguyên ảnh của phiên trước (daemon awww tự khôi phục từ cache `~/.cache/awww`) — nếu chưa có ảnh (máy mới / cache trống) mới tự random 1 ảnh
- **Đổi ảnh bất cứ lúc nào**: `$mod+r` (random — luôn khác ảnh đang dùng) hoặc `$mod+Shift+r` (menu rofi lưới thumbnail 3×3, tên dưới ảnh, xếp lấp trái→phải, `●` là ảnh đang dùng; >9 ảnh tự cuộn, phím `←→↑↓` duyệt ảnh). Không tự đổi theo giờ nữa.
- **Thêm/xoá ảnh**: `$mod+y` mở **yazi** popup ở thư mục hiện tại (xem [Thêm ảnh bằng yazi](#thêm-ảnh-bằng-yazi-mody))

### ⭐ Chưa có ảnh nào? Tự động dùng màu nền

**Không bao giờ thấy màn đen.** Khi `~/Pictures/wallpapers/` rỗng (máy mới vừa cài, hoặc vừa xoá hết ảnh), `wallpaper-set` tự đặt nền là **màu Catppuccin Mocha `#1e1e2e`** — màu nền dùng ở mọi nơi trong config.

```bash
awww img 0x1e1e2e        # awww nhận thẳng HEXCODE, không cần file ảnh
awww query               # → currently displaying: image: 0x1e1e2eff
```

- ✅ **0 byte** trong repo — không lo repo phình
- ✅ Máy mới cài xong đăng nhập là có nền đẹp, không lỗi, không phải copy ảnh gì cả
- ✅ Báo qua `notify-send` hướng dẫn thêm ảnh

> Khi đang ở chế độ màu, `wallpaper-menu` báo *"chưa có ảnh nào — thêm bằng yazi"* thay vì lỗi. Script cũng tự nhận ra giá trị hexcode và **không** cố `readlink` nó như đường dẫn file.

### Tự đổi ảnh nền mỗi 30 phút (auto-rotate)

⛔ **ĐÃ TẮT** — ảnh chỉ đổi khi bấm phím. Muốn bật lại: bỏ `#` ở 2 khối `wallpaper-rotate` trong `modules/nixos/desktop.nix`, rebuild, rồi `systemctl --user start wallpaper-rotate.timer`.

- Mốc 30 phút tính từ lần đổi gần nhất: `wallpaper-set` gọi `try-restart` timer sau mỗi lần đặt ảnh.
- Timer không `wantedBy` → không tự bật khi đăng nhập, phải start tay 1 lần.

**Thao tác nhanh — chọn nhanh đường đi:**

| Muốn | Cách làm | Rebuild? |
|---|---|---|
| Thêm ảnh | `$mod+y` (yazi popup) rồi `cd ~/Pictures/wallpapers`, hoặc `cp` vào thẳng `~/Pictures/wallpapers/` | ❌ Không |
| Xóa ảnh | `rm` trong `~/Pictures/wallpapers/` (yazi hỏi xác nhận) | ❌ Không |
| Thay ảnh cùng tên | `cp -f` đè file cũ | ❌ Không |
| Đổi tên ảnh | `mv` — không theo quy ước tên nào | ❌ Không |
| Thêm ảnh **mới vào repo** | ❌ Không làm — repo chỉ có `lockscreen/nixos.jpg` | — |

> ⚠️ Ảnh trong `~/Pictures/wallpapers/` giờ là **file thật của bạn** (không còn là symlink `/nix/store` read-only như trước) → `rm`/`cp -f` ghi đè đều thoải mái, không còn lỗi `Permission denied`.
>
> `.gitignore` của repo đã có dòng `wallpapers/` để chặn lỡ tay copy ảnh vào `~/nix-config/wallpapers/` rồi `git add`.

### Thêm ảnh bằng yazi (`$mod+y`)

Cách nhanh nhất, không cần nhớ lệnh. `$mod+y` mở yazi dạng **popup** ở thư mục hiện tại:

1. Bấm **`$mod+y`** → popup yazi mở ở thư mục terminal đang ở
2. Đi tới `~/Pictures/wallpapers`: bấm `~` (về home) → `Pictures` → `wallpapers`
3. Tới nơi ảnh nằm (ví dụ `~/Downloads`), bấm `y` để **copy** → quay lại thư mục ảnh → `p` để **paste**
4. `$mod+r` → ảnh mới hiện ngay

Xoá ảnh: bấm `d` trong yazi (hỏi xác nhận) — vào **thùng rác**, nên vẫn khôi phục được bằng `g` `t` nếu lỡ. Muốn xoá hẳn luôn thì bấm `D`. Tự dọn rác cũ lúc 03:00, xem [Thùng rác](#thùng-rác-tự-động-dọn-lúc-0300).

Config yazi gồm 3 file cùng thư mục `home/yazi/`, Yazi tự merge với mặc định nên không mất phím tắt nào. Đã đối chiếu từng khoá với `yazi-default.toml` + `keymap-default.toml` bản 26.5.6 (khoá không có trong đó thì yazi **lặng lẽ bỏ qua**).

**Cách mở — 2 kiểu khác nhau:**

| Cách | Kiểu cửa sổ | Dùng khi |
|---|---|---|
| `$mod+y` | **Popup** nhỏ (1000×700, floating) | Chọn nhanh: xem 1 file, thêm/xoá ảnh |
| Gõ `yazi` trong terminal | Cửa sổ thường, **không** popup | Duyệt file kỹ — preview ảnh/PDF bằng sixel đẹp hơn nhiều |

Popup chỉ là `foot --title=yazi-popup` + rule floating theo title đó trong `home/sway.nix` (yazi chạy **bên trong** foot nên phải match theo title chứ không phải app_id). Không có phím tắt riêng cho file picker — upload dùng hộp thoại native của trình duyệt.

| File | Chứa gì |
|---|---|
| `yazi.toml` | Hành vi: opener (mở `.txt` bằng foot+nvim), luật mở app theo phần mở rộng, tỉ lệ cột |
| `keymap.toml` | Phím tắt ghi đè: `<Enter>` → smart-enter (sửa lỗi Enter vào folder ra nvim) |
| `theme.toml` | Màu Catppuccin Mocha |

#### Plugin `smart-enter` (`<Enter>`)

`<Enter>` tự rẽ nhánh theo loại mục: **thư mục** thì đi vào, **file** thì mở app theo mime (`.txt` → foot+nvim, `.pdf` → sioyek, ảnh → imv, `.epub` → foliate…).

**Vì sao cần plugin này** (lỗi thật, đã test lỗi trước và sau khi sửa): preset yazi khai `{ mime = "folder/*", use = ["edit", "open", "reveal"] }` — `edit` đứng **đầu**; mà ta ghi đè opener `edit` thành nvim. Hai thứ ghép lại khiến **Enter vào thư mục lại ra nvim**. `smart-enter` bỏ qua bảng `use` với thư mục nên sửa đúng gốc, vẫn giữ nguyên thói quen bấm `<Enter>` để mở file.

- Cài gói `yaziPlugins.smart-enter`, link thành `~/.config/yazi/plugins/smart-enter.yazi` — khai trong `home/yazi.nix`.
- Plugin này **không cần** `setup()`. Mặc định nó truyền `--hovered` nên chỉ mở **đúng 1 file đang trỏ**, không mở cả nhóm đang chọn (khớp hành vi `enter`, tránh mở nhầm). Muốn mở cả nhóm thì thêm `require("smart-enter"):setup { open_multi = true }`.
- ⚠️ **Không xoá `init.lua`.** File đó đang tồn tại và **bắt buộc cho plugin `recycle-bin`** (xem bên dưới): `require("recycle-bin"):setup()`. Thiếu nó thì `config` = nil → các lệnh dùng `config.trash_dir` sẽ lỗi. Nội dung hiện tại đúng là chỉ dòng trên.

#### Phím tắt sau khi cấu hình

| Phím | Thư mục | File |
|---|---|---|
| `<Enter>` | ✅ vào thư mục | ✅ mở app theo mime |
| `l` / `<Right>` | ✅ vào thư mục | ⬜ không làm gì (giữ nguyên preset — chỉ để đi vào folder) |
| `h` | ✅ ra thư mục cha | — |
| `g` `t` | Menu thùng rác (duyệt / khôi phục / dọn) — xem [Thùng rác](#thùng-rác-tự-động-dọn-lúc-0300) | |
| `d` / `D` | Xoá mềm / xoá hẳn | |

> ⭐ **Xem trước ảnh trong yazi hoạt động nhờ terminal là `foot`**: foot xuất `TERM=foot` và hỗ trợ **sixel**, yazi nhận ra ngay và vẽ ảnh thật trong khung preview — không cần cài thêm gói nào. (Alacritty không có kitty-graphics lẫn sixel, nên yazi phải gọi `ueberzugpp`, vốn vẽ ảnh ở layer-surface phía **sau** terminal → terminal phải trong suốt mới thấy.)

### Thêm ảnh (dòng lệnh)

```bash
cp ~/Downloads/hinh-moi.jpg ~/Pictures/wallpapers/hinh-moi.jpg
```

Xong — dùng được ngay. Không sửa file `.nix` nào, không rebuild, không commit. Ảnh mới nằm trong vòng random ngay lần `$mod+r` kế tiếp.

### Xóa ảnh

```bash
rm ~/Pictures/wallpapers/ten-anh.jpg
```

💡 Nếu xóa đúng ảnh **đang hiển thị**: bấm `$mod+r` đổi sang ảnh khác *trước*. (Hệ thống vẫn tự phục hồi — daemon giữ ảnh trong bộ nhớ, lần đăng nhập sau cache trỏ file mất thì `wallpaper-set --if-empty` tự rơi về random — nhưng đổi trước vẫn gọn hơn.)

### Thay thế / đổi tên ảnh

**Thay bản đẹp hơn, giữ nguyên tên**:

```bash
cp -f ~/Downloads/anh-dep-hon.jpg ~/Pictures/wallpapers/ten-cu.jpg
```

**Đổi tên** (script không theo quy ước tên nào — tự do đặt lại, ảnh vẫn random như thường):

```bash
mv ~/Pictures/wallpapers/cu.jpg ~/Pictures/wallpapers/moi.jpg
```

**Ảnh màn hình khoá**: đây là ảnh **duy nhất còn trong repo** — thay đúng file `lockscreen/nixos.jpg` (tên cố định, được chèn thẳng vào script `lock-screen`) rồi rebuild:

```bash
cp -f ~/Downloads/anh-khoa.jpg ~/nix-config/lockscreen/nixos.jpg
sudo nixos-rebuild switch --flake ~/nix-config#laptop
```

> ⚠️ Git giữ mọi phiên bản cũ của file binary → thay `lockscreen/nixos.jpg` nhiều lần làm lịch sử repo phình dần. Vì thế ảnh nền đã bị đẩy ra ngoài repo: chỉ còn đúng 1 ảnh trong `lockscreen/`, thay bao nhiêu lần cũng không phình.

### Lệnh tay

| Lệnh | Việc |
|---|---|
| `~/.local/bin/wallpaper-set` | Đổi sang ảnh random khác |
| `~/.local/bin/wallpaper-set <đường-dẫn-ảnh>` | Đặt đúng ảnh chỉ định |
| `~/.local/bin/wallpaper-menu` | Mở menu chọn ảnh lưới 3×3 (như `$mod+Shift+r`) |
| `awww query` | Xem ảnh đang hiển thị |
| `ls ~/Pictures/wallpapers/` | Danh sách ảnh thực tế (kiểm tra sau thêm/xóa) |

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

## Mở file ≠ Xem trước (preview)

Hai việc khác nhau, dùng cơ chế khác nhau — đừng lẫn:

| Việc | Làm gì | Cần gì | Cấu hình ở đâu |
|---|---|---|---|
| **Mở** file | Mở app thật, cửa sổ riêng | App theo mime: imv / mpv / sioyek / foliate / Chrome / nvim | `home/mimeapps.nix` |
| **Xem trước** | Vẽ ảnh nhỏ **tại chỗ** (khung phải trong yazi, ảnh thu nhỏ trong Thunar) | Ảnh: terminal hỗ trợ **sixel** (foot ✅) · Thunar: `tumbler` | `home/foot.nix`, `modules/nixos/desktop.nix` |

**Trong yazi preview được ẢNH, PDF, video và SVG.** Không cần cài gì thêm: gói `yazi` của nixpkgs đã đóng gói sẵn `poppler-utils`, `ffmpeg`, `resvg`, `imagemagick`, `chafa`… và wrapper tự thêm chúng vào PATH mỗi khi chạy yazi. (Vì vậy `command -v pdftoppm` ở terminal báo *không có* — nhưng bên trong yazi thì có.) Ảnh hiển thị đẹp nhờ foot hỗ trợ **sixel**.

Bấm `Enter` vẫn mở app thật (`sioyek` / `mpv` / `imv`), preview chỉ là xem nhanh. Muốn xác nhận các lệnh trên có thật không: chạy `yazi --debug` rồi xem PATH của tiến trình.

Đổi app mặc định cho 1 loại file: sửa `home/mimeapps.nix` → `nh os switch` → kiểm tra `xdg-mime query default image/jpeg`. **Đừng sửa tay `~/.config/mimeapps.list`** — nó là symlink do Home-Manager quản lý, sẽ bị ghi đè.

## Thunar (file manager đồ hoạ)

Dùng khi cần chuột + kéo thả giữa các nơi (yazi vẫn là chính cho việc thường ngày).

| Việc | Cách |
|---|---|
| Ảnh thu nhỏ trong danh sách | Có sẵn nhờ `tumbler` (`programs.thunar.plugins`). Vào **Icon view** mới thấy rõ |
| Mở terminal tại thư mục đang xem | Nút phải chuột → *Open Terminal Here* — tự mở **foot** (đọc `TerminalEmulator` trong `home/thunar.nix`) |
| Xoá file | *Move to Trash* → vào thùng rác (xem mục dưới) |
| Nén / giải nén | Dùng lệnh `7z` (`p7zip`) — **không** có plugin giải nén trong menu |
| Cắm USB / thẻ nhớ | Thunar **không** tự mount — mount tay theo [04 — Sao lưu](04-Sao-Luu-Phuc-Hoi.md) |

## Thùng rác (tự động dọn lúc 03:00)

Thùng rác GIO **luôn hoạt động** vì `services.gvfs.enable` (khai ở `modules/nixos/desktop.nix`) — không có option nào phải bật thêm. Nằm ở `~/.local/share/Trash` (`files/` = file thật, `info/` = `.trashinfo` ghi đường dẫn gốc + ngày xoá).

| Phím trong yazi | Việc |
|---|---|
| `d` | Xoá → **vào thùng rác** (xoá mềm) |
| `D` | Xoá **vĩnh viễn** — không khôi phục được, dùng khi dọn file rác chắc chắn |
| `g` `t` | Menu thùng rác (xem bên dưới) |

> ⚠️ **Bản yazi 26.5.6 CHƯA có sẵn** scheme `trash://` lẫn phím `g t` gốc — đó là tính năng của bản nightly (đã kiểm trực tiếp binary: không có chuỗi nào). Nên `g t` ở đây là **plugin `recycle-bin`** khai trong `home/yazi.nix` + `home/yazi/keymap.toml`, cần gói `trash-cli`. Nếu xoá 2 chỗ đó, `g t` sẽ hết tác dụng (nhưng `d` vẫn xoá mềm bình thường). Phím `g t` là **đúng preset chính thức của yazi** (đã grep preset `main` trên GitHub: `{ on = ["g","t"], run = "plugin trash", desc = "Go to trash bin" }`), cùng nhóm với `g h`/`g c`/`g d`/`g f`.
>
> Nếu không muốn dùng plugin, xem thẳng `~/.local/share/Trash/files` trong yazi cũng được — đó là thư mục thật, chỉ thiếu chức năng khôi phục tự động.

**Menu `g t` (plugin `recycle-bin`):**

| Phím trong menu | Việc |
|---|---|
| `o` | Mở thư mục thùng rác để duyệt |
| `r` | **Khôi phục** file đã chọn về chỗ cũ (tick nhiều file bằng `Space` trước; tự xử lý xung đột khi chỗ cũ đã có file) |
| `d` | Xoá vĩnh viễn các mục đã chọn (có hỏi xác nhận) |
| `e` | Dọn sạch toàn bộ (có xem trước danh sách + dung lượng) |
| `D` | Dọn mục **cũ hơn 30 ngày** — trùng chức năng timer lúc 3h, dùng để dọn ngay trong phiên |

Dùng bằng lệnh:

```bash
gio trash --list                      # xem trong thùng rác có gì (kèm đường dẫn gốc)
gio trash --restore 'trash:///...%20'  # khôi phục 1 file về chỗ cũ
gio trash --empty                     # XOÁ HẾT, không hồi phục được
trash-clean                           # tự dọn mục > 30 ngày (timer gọi lúc 3h)
trash-clean 7                         # thử với 7 ngày, xem sẽ xoá bao nhiêu
```

**Tự động dọn:** systemd **user** timer `trash-clean.timer`, chạy **03:00 hằng ngày**, xoá mục **cũ hơn 30 ngày** (`trash-clean 30`).

| Ý nghĩa | Chi tiết |
|---|---|
| Vì sao **30 ngày** | Thùng rác là vùng an toàn khôi phục file lỡ xoá. 30 ngày = cửa sổ đủ rộng mà rác không phình vô hạn. Đổi số trong `ExecStart` ở `modules/nixos/desktop.nix` |
| Vì sao **không** dùng `gio trash --empty` | Lệnh đó xoá **sạch** — file bạn lỡ xoá tối qua sẽ mất vĩnh viễn lúc 3h sáng, không kịp `g t` khôi phục. Script chỉ xoá mục cũ |
| `Persistent=true` | Bắt buộc — máy tắt/hibernate lúc 3h thì timer đó bị bỏ qua; `Persistent` cho chạy **bù** khi bật máy |
| User timer, **không** system timer | `gio trash` cần `XDG_RUNTIME_DIR` + dbus. System timer thiếu → hỏng mà không báo lỗi rõ |

Kiểm tra timer:

```bash
systemctl --user list-timers trash-clean.timer   # lần chạy kế tiếp
systemctl --user status trash-clean.service      # kết quả lần gần nhất
journalctl --user -u trash-clean.service -n 20   # log
```

> Thùng rác nằm trong `~/` → **không** đồng bộ sang máy khác. Xem `docs/04` về backup.

## Xem ảnh • video • sách điện tử

Mỗi loại file có **app riêng**, khai ở `home/mimeapps.nix` (`xdg.mimeApps`). Không mở ảnh/video local bằng Chrome — Chrome nặng, mỗi tấm 1 tab, không có zoom/timeline/tua nhanh.

| Loại file | App | Phím tắt / ghi chú |
|---|---|---|
| Ảnh (jpg, png, webp…) | **imv** | `←/→` ảnh trước/sau · `+`/`-` zoom · `f` vừa màn hình · `Ctrl+C` copy ảnh |
| Video / audio | **mpv** | `←/→` tua 5s · `↑/↓` tua 60s · `f` toàn màn · `m` tiếng · `,`/`.` lùi/nhanh |
| PDF | **sioyek** | Đọc tài liệu khoá học/kỹ thuật (đã khai sẵn) |
| EPUB / MOBI / AZW3 / FB2 / CBZ | **foliate** | Trình đọc chuyên dụng, dùng WebKitGTK nên typography đẹp hơn hẳn `calibre-ebook-viewer`. Xem [Sách điện tử](#sách-điện-tử-foliate) |
| File text / code | **nvim** | Mở thẳng trong cửa sổ foot mới |
| Web / link / HTML | **google-chrome** | Mọi `http(s)://`, file `.html`/`.xhtml` |

### Sách điện tử: foliate

**calibre đã được gỡ.** Thư viện chuyển sang thư mục phẳng, không cần app quản lý:

| Thư mục | Chứa gì | Mở bằng |
|---|---|---|
| `~/Books/Textbooks` | Sách kỹ thuật (PDF) | sioyek |
| `~/Books/Reading` | Sách tự do (epub, azw3) | foliate |

Thư mục nằm **ngoài repo** — thêm/xoá sách thoải mái, không rebuild, không commit. Xem `docs/04` về backup.

Vì sao bỏ calibre: nó thêm ~2.9 GB closure chỉ để quản lý 27 file, và `calibre-ebook-viewer` render bằng Qt nên typography kém hơn hẳn foliate (WebKitGTK). Đổi lại mất `ebook-convert` (chuyển đổi định dạng) — không sao, tải sách nên chọn thẳng epub/pdf. Cũng mất đọc LRF (Sony), nhưng thư viện không có file .lrf nào.

```bash
# Mở app mặc định của 1 loại file
xdg-mime query default image/jpeg     # → imv.desktop
xdg-mime query default video/mp4      # → mpv.desktop
xdg-mime query default application/epub+zip   # → com.github.johnfactotum.Foliate.desktop
xdg-mime query default application/pdf        # → sioyek.desktop

# Mở sách
yazi ~/Books/Reading     # duyệt cả thư viện
xdg-open ~/Books/Reading/*.epub   # mở thẳng 1 cuốn
```

**Cấu hình foliate: KHÔNG quản lý bằng Nix** — repo chỉ cài gói (`home/packages.nix`) và khai app mặc định (`home/mimeapps.nix`). Mọi tuỳ chọn đọc (font, cỡ chữ, nền, giãn dòng) chỉnh trực tiếp trong app: `~` trong yazi rồi `Enter` trên 1 file epub, hoặc chạy thẳng `foliate ~/Books/Reading/*.epub`.

> ⚠️ **Lưu ý khi bật "Căn đều 2 mép" (justify):** WebKitGTK (engine render) hardcode tìm từ điển ngắt từ ở `/usr/share/hyphen` — thư mục này không tồn tại mặc định trên NixOS, nên `modules/nixos/desktop.nix` khai `systemd.tmpfiles` tạo symlink tới `hyphenDicts.en_US`. **Nếu tự ý xoá khối `systemd.tmpfiles` đó, foliate vẫn chạy nhưng sẽ im lặng mất ngắt từ** (chữ bị dãi lỗ hổng giữa các từ).
>
> Đây là sửa ở tầng **hệ thống** cho WebKitGTK nên giữ lại dù không khai file config cho foliate — có lợi cho mọi app dùng WebKit (Epiphany, wpewebkit…), không chỉ foliate.

**Lưu ý về mime mobi:** mime đúng là `application/x-mobipocket-ebook` và `application/vnd.amazon.mobi8-ebook`. Nếu thấy `application/x-mobi8-ebook` ở đâu đó → đó là mime bịa, dòng mapping đó không bao giờ được dùng (đã sửa trong `home/mimeapps.nix`).

> ⚠️ File `~/.config/mimeapps.list` giờ do **Home-Manager quản lý** (symlink tới `/nix/store`) — muốn đổi app mặc định thì sửa `home/mimeapps.nix` rồi rebuild, **đừng sửa tay file trong `~`** (sẽ bị ghi đè). File cũ sửa tay được giữ lại thành `mimeapps.list.backup`.
>
> Lưu ý: `text/plain` cố ý trỏ về `nvim.desktop` → double-click file `.txt`/`.log`/`.csv` sẽ **mở nvim** trong terminal.

## Terminal: Foot (không có "acrylic" trên Sway)

- Terminal là **foot** (`$mod+Return` mở cửa sổ mới). Lý do đổi từ Alacritty: foot hỗ trợ **sixel** nên yazi xem trước ảnh thật.
- **Hiệu ứng blur ("acrylic") không tồn tại trên Sway** — Sway không implement protocol blur nào. Foot *có* khoá `blur = yes` nhưng nó cần protocol `ext-background-effect-manager-v1` (chỉ KDE Plasma 6.1+ có) nên trên Sway foot chỉ log `disabling background blur` rồi bỏ qua; Alacritty cũng tương tự (blur chỉ chạy macOS/KDE). Ở đây chỉ có **trong suốt phẳng** (`alpha = 0.9` trong `home/foot.nix`).
- Muốn cảm giác kính mờ: đặt sẵn **ảnh nền đã blur** vào `~/Pictures/wallpapers/` rồi đổi ảnh đó (`$mod+r`) → terminal trong suốt nằm trên nền mờ trông gần giống acrylic.
- Sửa `home/foot.nix` rồi `nh os switch` là xong. **Kiểm tra config foot không cần mở cửa sổ**: `foot -C` → in `err: config.c:…` và exit 1 nếu sai cú pháp (sai màu hay gặp nhất, xem chú thích trong `home/foot.nix`).

## Sự cố thường gặp

| Triệu chứng | Kiểm tra |
|---|---|
| Sway không khởi động | `journalctl -b -u greetd` |
| Mất âm thanh | `systemctl status pipewire` → `systemctl --user restart wireplumber` |
| Bộ gõ kẹt | `fcitx5-diagnose` |
| Yazi không xem trước ảnh | Ảnh phải hiện (foot hỗ trợ sixel). Kiểm tra `echo $TERM` trong terminal đang chạy yazi phải ra `foot` — nếu là `xterm-256color` thì terminal khác đã mở yazi, đóng đi mở lại từ foot. Hover PDF/video/SVG thì báo lỗi là **bình thường** (xem [Mở file ≠ Xem trước](#mở-file--xem-trước-preview)) |
| Double-click file mở app không đúng | `xdg-mime query default <mime>` xem app đang được gán; sửa `home/mimeapps.nix` rồi rebuild (đừng sửa tay `~/.config/mimeapps.list` — nó là symlink do Home-Manager quản lý) |
| Wallpaper không đổi | `systemctl --user status awww-daemon` (daemon giữ ảnh nền); test tay: `~/.local/bin/wallpaper-set`. Script tự loại ảnh đang hiển thị nên bấm `$mod+r` luôn ra ảnh mới; menu `$mod+Shift+r` hiện lưới thumbnail 3×3, tên dưới ảnh (ảnh đang dùng có dấu `●`). Lưu ý: auto-rotate 30 phút **đã tắt** nên nền sẽ KHÔNG tự đổi |
| Hibernate không dậy | `cat /proc/cmdline` phải có `resume=/dev/disk/by-label/swap`; `swapon --show` phải thấy phân vùng swap (nhãn `swap`) |

## Liên quan

- [01-Tong-Quan-He-Thong](01-Tong-Quan-He-Thong.md) — hệ thống có những gì
- [03-Cai-May-Moi](03-Cai-May-Moi.md) — khi máy hỏng nặng / máy mới
- [04-Sao-Luu-Phuc-Hoi](04-Sao-Luu-Phuc-Hoi.md) — backup trước khi rủi ro
