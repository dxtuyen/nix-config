{ pkgs, ... }:

{
  programs.sway.enable = true;
  programs.dconf.enable = true;
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
      user = "greeter";
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.power-profiles-daemon.enable = true;
  hardware.bluetooth.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [ pkgs.fcitx5-unikey ];
  };

  fonts.packages = with pkgs; [ jetbrains-mono font-awesome ];

  environment.systemPackages = with pkgs; [
    alacritty waybar rofi-wayland mako
    wlsunset grim slurp wl-clipboard swaylock swayidle
    libnotify pavucontrol brightnessctl
    thunar networkmanagerapplet blueman polkit_gnome
    google-chrome zathura calibre
  ];
}
