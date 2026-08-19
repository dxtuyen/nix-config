# 04 - Sway desktop

## Sway la gi

Sway la **window manager** (trinh quan ly cua so) chay tren Wayland.
No quan ly: cua so, workspace, phim tat, wallpaper, idle.

## Cau hinh o dau

- `home/sway.nix` = cau hinh Sway (phim tat, workspace, rules, idle).
- `home/waybar.nix` = thanh trang thai (top bar).
- `home/foot.nix` = terminal mac dinh.
- `home/mako.nix` = trinh thong bao.
- `home/gtk.nix` = theme, icon, cursor.

## Cau truc sway.nix

```nix
wayland.windowManager.sway = {
  enable = true;
  extraConfig = ''
    # Phim tat, workspace, rules...
  '';
};
```

## Phim tat chinh

| Phim | Chuc nang |
|------|-----------|
| `mod+Return` | Mo terminal (foot) |
| `mod+d` | Mo launcher Rofi |
| `mod+Shift+q` | Dong cua so |
| `mod+1..0` | Chuyen workspace |
| `mod+Shift+1..0` | Di chuyen cua so sang workspace |
| `mod+f` | Fullscreen |
| `mod+space` | Toggle floating |
| `mod+r` | Mode resize |

## Vi sao dung Sway

- **Nhe**: khong phai desktop day du (GNOME/KDE), chi quan ly cua so.
- **Wayland native**: hien dai, muot, bao mat.
- **Cau hinh bang text**: de version control, de tai su dung.

## Lien quan

- [[01-Kien-truc-tong-quan]] - vi tri cua sway trong repo
- [[03-Home-Manager]] - sway la user config
- [[05-Cau-chuyen-Thunar]] - vi du thuc te ve desktop entry
