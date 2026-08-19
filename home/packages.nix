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
  ];
}
