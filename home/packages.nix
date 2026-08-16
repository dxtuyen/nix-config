{ pkgs, ... }:

{
  home.packages = with pkgs; [
    alacritty
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
    jq
  ];
}
