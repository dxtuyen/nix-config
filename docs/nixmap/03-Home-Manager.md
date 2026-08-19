# 03 - Home Manager

## Home Manager la gi

Home Manager la cong cu cua Nix de quan ly **cau hinh user**.
Trong khi NixOS quan ly he thong (can root), Home Manager quan ly
`~/.config`, `~/.local/bin`, goi cai cho user.

## Vi tri trong repo

- `home/default.nix` = diem vao. Import tat ca file trong `home/`.
- Moi file trong `home/` = mot module Home Manager.

## Cac file trong home/

| File | Noi dung |
|------|----------|
| `default.nix` | Diem vao, import tat ca, bat xdg.enable, PATH ~/.local/bin |
| `packages.nix` | Goi cai qua home.packages (rofi, thunar, obsidian...) |
| `foot.nix` | Terminal Foot (theme Tokyo Night) |
| `gtk.nix` | GTK theme, icon, cursor |
| `sway.nix` | Cau hinh Sway (window manager) |
| `waybar.nix` | Thanh trang thai Waybar |
| `mako.nix` | Trinh thong bao Mako |
| `fcitx5.nix` | Bo go tieng Viet Fcitx5 |
| `scripts.nix` | Script thu cong trong ~/.local/bin |
| `remnote.nix` | RemNote AppImage |
| `thunar.nix` | Dang ky Foot lam terminal + entry Neovim |

## Vi sao tach nhu vay

- **Moi file mot chu de**: de tim, de sua.
- **Import trung tam**: `default.nix` la noi duy nhat import. De biet co gi.
- **Tai su dung**: muon them may moi, chi can import `home/`.

## Vi sao co xdg.enable o default.nix

`xdg.enable = true` bat kha nang tao file `.desktop` va cau hinh MIME.
Dat o `default.nix` (entry point) de **mot noi duy nhat** quan ly nen tang,
con module con (remnote, thunar...) chi khai bao noi dung.

## Lien quan

- [[01-Kien-truc-tong-quan]] - vi tri cua home trong repo
- [[02-Nguyen-ly-NixOS]] - khac biet system vs user
- [[04-Sway-desktop]] - cau hinh UI
- [[05-Cau-chuyen-Thunar]] - vi du thuc te dung xdg
