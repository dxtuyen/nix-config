{
  config,
  lib,
  pkgs,
  ...
}:

let
  fcitxPackage = config.i18n.inputMethod.package;
  fcitxAddons = config.i18n.inputMethod.fcitx5.addons;
  fcitxAddonDirs = lib.makeSearchPath "lib/fcitx5" fcitxAddons;
  fcitxDataDirs = lib.makeSearchPath "share/fcitx5" fcitxAddons;
in
{
  programs.sway.enable = true;
  programs.dconf.enable = true;

  # GVFS: daemon virtual-filesystem cung cap "Move to Trash" (thung rac),
  # mount USB, reserved space v.v. cho cac file manager GTK nhu Thunar.
  # Thieu GVFS thi Thunar se XOA THANG vi khong co cho de chuyen vao thung rac.
  services.gvfs.enable = true;

  # GPU acceleration chuẩn từ NixOS 24.05 trở lên
  hardware.graphics.enable = true;

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
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

  # XDG Desktop Portal cho Sway / wlroots
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [ "gtk" ];
      sway = {
        default = lib.mkForce [
          "wlr"
          "gtk"
        ];
      };
    };
  };

  # Cấu hình bộ gõ Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-unikey
      fcitx5-gtk
    ];
  };

  environment.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    # Bắt buộc các app Electron / Chromium chạy native Wayland
    NIXOS_OZONE_WL = "1";
  };

  fonts = {
    packages = with pkgs; [
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      font-awesome
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      monospace = [ "JetBrains Mono" ];
    };
  };

  systemd.user.services.fcitx5-daemon = {
    description = "Fcitx5 input method daemon";
    wantedBy = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${fcitxPackage}/bin/fcitx5";
      Environment = [
        # Fcitx ignores addon metadata exposed as buildEnv symlinks.
        "FCITX_ADDON_DIRS=${fcitxAddonDirs}:${fcitxPackage}/lib/fcitx5"
        "FCITX_DATA_DIRS=${fcitxDataDirs}:${fcitxPackage}/share/fcitx5"
      ];
      Restart = "always";
      RestartSec = "2";
    };
  };
}
