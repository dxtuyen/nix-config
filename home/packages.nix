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
    polkit_gnome
    google-chrome
    calibre
    sioyek
    ticktick
    obsidian
    anki
    jq
    fastfetch

    # Máy ảo — luyện tập cài máy mới theo docs/06-Luyen-Tap-VM.md (QEMU trực tiếp + KVM)
    qemu
    qemu-utils
    OVMF
  ];
}
