{ pkgs, inputs, ... }:

# Ghi chú: `ticktick` được lấy từ nixpkgs-unstable (khai trong flake.nix) vì
# TickTick phát hành bản chính thức sớm hơn; gói đóng gói vào nhánh stable
# (nixos-26.05) thường chậm vài phiên bản. Cách dùng:
#   nix flake update nixpkgs-unstable   # nâng input unstable lên bản mới nhất
#   sudo nixos-rebuild switch --flake .#laptop
# Các gói còn lại trong list này vẫn dùng nixpkgs stable (biến `pkgs`).

let
  # Instance nixpkgs-unstable có cấu hình riêng để khớp hệ thống (allowUnfree).
  # legacyPackages thông thường sẽ chặn gói unfree (v.d. ticktick) vì không
  # kế thừa nixpkgs.config.allowUnfree = true từ core.nix.
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config = {
      allowUnfree = true;
      permittedInsecurePackages = pkgs.config.permittedInsecurePackages or [ ];
    };
  };
in
{
  home.packages = with pkgs; [
    rofi
    wlsunset
    grim
    slurp
    wl-clipboard
    swaylock
    swayidle
    libnotify
    pavucontrol
    brightnessctl
    translate-shell
    goldendict-ng
    thunar
    networkmanagerapplet
    blueman
    google-chrome
    calibre
    sioyek
    obsidian
    anki
    jq
    fastfetch
    libreoffice
    unrar
    # Lấy bản mới nhất của ticktick từ nixpkgs-unstable
    unstable.ticktick
    # Máy ảo — luyện tập cài máy mới theo docs/06-Luyen-Tap-VM.md
    # qemu_kvm: bản QEMU chỉ target x86_64 + KVM, nhẹ hơn meta-package qemu
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
