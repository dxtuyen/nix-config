{
  config,
  lib,
  pkgs,
  userName,
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

  # GVFS hỗ trợ tài nguyên từ xa và filesystem ảo cho GIO/Thunar.
  services.gvfs.enable = true;

  # Thunar chính thức + plugin giải nén/nén tích hợp vào context menu.
  # Không khai báo `thunar` trong home.packages để tránh bản user-level
  # thiếu plugin đè lên package có plugin do NixOS module tạo ra.
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
    ];
  };

  # File Roller là frontend archive cho plugin Thunar; các backend được đặt
  # trong PATH của hệ thống để hỗ trợ RAR/7z/ZIP và tạo archive mới.
  environment.systemPackages = with pkgs; [
    file-roller
    p7zip
    unrar
  ];

  hardware.graphics.enable = true;

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      # Điền sẵn username (vẫn hỏi mật khẩu, không auto-login).
      command = "${pkgs.tuigreet}/bin/tuigreet --time --user ${userName} --cmd sway";
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

  # Module Sway đã cung cấp portal GTK/WLR và cấu hình mặc định cho Sway.
  # Giữ enable tường minh để module này không phụ thuộc vào đường dẫn import.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  # Cấu hình bộ gõ Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-bamboo
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
      Restart = "on-failure";
      RestartSec = "2";
    };
  };
}
