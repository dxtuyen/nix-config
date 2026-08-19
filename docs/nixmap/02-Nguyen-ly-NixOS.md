# 02 - Nguyen ly NixOS

## Y tuong cot loi

NixOS khong "cai phan mem" vao he thong nhu Ubuntu.
Thay vao do, NixOS **xay dung** toan bo he dieu hanh tu mot "cong thuc" (flake).

## Module la gi

Mot module NixOS la mot file `.nix` khai bao **mot phan** cua he dieu hanh.
Vi du:

- `modules/nixos/core.nix` = phan long: nix settings, network, user, goi co ban.
- `modules/nixos/desktop.nix` = phan desktop: Sway, greetd, pipewire, font, fcitx5.
- `modules/nixos/development.nix` = phan dev: VS Code, Python, GCC, Podman.
- `modules/nixos/laptop.nix` = phan laptop: battery threshold, keyd, fwupd.

## Cau truc mot module

```nix
{ pkgs, ... }:   # nhan tham so

{
  # Khai bao cau hinh o day
  environment.systemPackages = with pkgs; [ git curl ];
  services.pipewire.enable = true;
}
```

## Vi sao dung module

- **Tach biet**: moi module lo mot viec. De doc, de sua.
- **Tai su dung**: may moi chi can import module da co.
- **Khong xung dot**: Nix tu hop nhat cac khai bao lai voi nhau.

## Cac file trong modules/nixos/

| File | Noi dung chinh |
|------|----------------|
| `core.nix` | Nix settings, network, user, goi co ban (git, curl, neovim, file...) |
| `desktop.nix` | Sway, greetd, pipewire, fcitx5, font, GPU |
| `development.nix` | VS Code, Python, GCC, CMake, Podman |
| `laptop.nix` | Battery threshold 80-85%, keyd remap, fwupd |

## Lien quan

- [[01-Kien-truc-tong-quan]] - vi tri cua module trong repo
- [[03-Home-Manager]] - khac biet giua system va user
- [[06-Thu-tuc-rebuild]] - cach ap dung thay doi
