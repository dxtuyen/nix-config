# 01 - Kien truc tong quan

## Muc tieu cua repo nay

Repo nay dung de **mo ta toan bo he dieu hanh cua ban** bang code.
Khong phai "cai phan mem" ma la "khai bao he dieu hanh se nhu the nao".

## Hai tang chinh

| Tang | Thu muc | Quan ly | Vi du |
|------|---------|---------|-------|
| He dieu hanh (system) | `modules/nixos/` | NixOS | Sway, greetd, pipewire, font, user |
| Nguoi dung (user) | `home/` | Home Manager | Sway config, Waybar, Foot, scripts |

## Dien giai

- `modules/nixos/` = nhung thu can **root** de cai: window manager, audio, display manager, user account.
- `home/` = nhung thu cua **user**: cau hinh app, phim tat, script ca nhan, theme.

## Dien vao dau

- `flake.nix` = diem vao. Noi khai bao dung nixpkgs + home-manager + host.
- `hosts/laptop/default.nix` = cau hinh cho may "laptop". Import cac module.
- `home/default.nix` = diem vao cua Home Manager. Import tat ca file trong `home/`.

## Vi sao chia nhu vay

- **Tai su dung**: module `core.nix` dung chung cho moi may. May moi chi can import.
- **De bao tri**: sua 1 noi, ap dung moi noi.
- **Ranh gioi ro**: thu gi can root, thu gi cua user.

## Lien quan

- [[02-Nguyen-ly-NixOS]] - hieu sau ve module
- [[03-Home-Manager]] - hieu sau ve user config
- [[06-Thu-tuc-rebuild]] - cach ap dung thay doi
