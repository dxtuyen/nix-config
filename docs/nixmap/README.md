# Nix-Config Map - Bat dau tai day

Vault Obsidian hoc toan bo cau truc repo nix-config.
Mo thu muc `nix-config/docs/nixmap/` nhu mot Vault trong Obsidian.

## Cach dung

Moi file md duoi day giai thich mot phan cua repo.
Khong can doc tuan tu, di theo lien ket [[brackets]] de kham pha.
Moi bai gi quyen DINH + NGUYEN LY + VI SAO.

## Danh muc

| # | File | Noi dung |
|---|------|----------|
| 00 | [[README]] | Ban dang o day |
| 01 | [[01-Kien-truc-tong-quan]] | Toan bo repo xoay quanh cai gi |
| 02 | [[02-Nguyen-ly-NixOS]] | NixOS Module la gi, hop thanh he dieu hanh |
| 03 | [[03-Home-Manager]] | User config: apps, scripts, desktop |
| 04 | [[04-Sway-desktop]] | Sway, Waybar, RoFi, Mako, Foot |
| 05 | [[05-Cau-chuyen-Thunar]] | Cau chuyen thuc te: Khac Thunar | 
| 06 | [[06-Thu-tuc-rebuild]] | Lenh rebuild, rollback, nixos-rebuild |
| 07 | [[07-Thuat-gon-demo]] | Glossary don gian |

## Toi nen doc gi truoc

Neu muon di tu dau den cuoi:

1. [[01-Kien-truc-tong-quan]] - hieu ban do
2. [[02-Nguyen-ly-NixOS]] - hieu trich thiet HDH
3. [[03-Home-Manager]] - hieu user-level
4. [[04-Sway-desktop]] - hieu UI
5. [[05-Cau-chuyen-Thunar]] - ap dung thuc te
6. [[07-Glossary]] - tra cuu bat ky luc nao

## Khong bao gio quen

- Sau khi `sudo nixos-rebuild switch --flake .#laptop`/`nh os switch` thi moi ap dung
- `nh os switch` tuong duong nanti, vit ngon
- Cac thanh phan tre moi luu luc logic chuyen day du va build-se veri
