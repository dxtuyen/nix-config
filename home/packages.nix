{ pkgs, ... }:

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
    ticktick
    obsidian
    anki
    jq
    fastfetch
    libreoffice
    unrar
    # Máy ảo — luyện tập cài máy mới theo docs/06-Luyen-Tap-VM.md
    # qemu_kvm: bản QEMU chỉ target x86_64 + KVM, nhẹ hơn meta-package qemu
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
