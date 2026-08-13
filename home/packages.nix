{ pkgs, ... }:

{
  home.packages = with pkgs; [
    adwaita-icon-theme
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
    wireplumber
    thunar
    networkmanagerapplet
    blueman
    polkit_gnome
    google-chrome
    zathura
    calibre
    ticktick
  ];
}
