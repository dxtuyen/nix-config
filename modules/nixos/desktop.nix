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

  # Thunar cho việc đồ hoạ. Không khai trong home.packages để tránh bản
  # user-level thiếu plugin đè lên package của NixOS module.
  # `tumbler` = dịch vụ ảnh thu nhỏ. KHÔNG thêm thunar-archive-plugin (kéo cả
  # GNOME stack) và thunar-volman (mount USB thủ công) — xem docs/02.
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      tumbler
    ];
  };

  # Chỉ giữ backend nhẹ: `7z` xử lý zip/7z/rar… đủ dùng, không kéo GNOME.
  environment.systemPackages = with pkgs; [
    p7zip
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
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

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

  # Hyphenation cho WebKitGTK (foliate justify không lỗ hổng). Chỉ cài
  # `hyphenDicts` KHÔNG đủ: WebKitGTK hardcode /usr/share/hyphen và
  # /usr/local/share/hyphen (không tồn tại trên NixOS) → phải trỏ symlink.
  # Chỉ en_US: thư viện chủ yếu sách tiếng Anh, hyphenDicts không có sẵn tiếng Việt.
  systemd.tmpfiles.rules = [
    "L+/usr/share/hyphen - - - - ${pkgs.hyphenDicts.en_US}/share/hyphen"
  ];

  # Dọn thùng rác (script xoá cả file lẫn .trashinfo, giữ 30 ngày gần nhất).
  # ⚠️ USER timer, KHÔNG phải system timer: `gio trash` cần XDG_RUNTIME_DIR +
  # DBUS_SESSION_BUS_ADDRESS, system timer thiếu 2 biến này → hỏng im lặng.
  systemd.user.services.trash-clean = {
    description = "Dọn thùng rác (giữ 30 ngày gần nhất)";
    serviceConfig.ExecStart = "%h/.local/bin/trash-clean 30";
  };

  systemd.user.timers.trash-clean = {
    description = "Dọn thùng rác lúc 03:00 hằng ngày (xoá mục > 30 ngày)";
    # `systemd.user.timers` dùng tên option CỦA SYSTEMD GỐC (timerConfig.*),
    # không phải kiểu rút gọn như `systemd.timers` cấp hệ thống.
    unitConfig.After = [ "graphical-session.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      # Máy tắt lúc 3h (hay dùng hibernate) sẽ bỏ qua timer; Persistent = chạy
      # BÙ lần sau. Timer chạy sau graphical-session.target để có môi trường desktop.
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # Tự đổi ảnh nền mỗi 30 phút — ĐÃ TẮT. Bỏ `#` mọi dòng dưới đây + rebuild
  # + `systemctl --user start wallpaper-rotate.timer`.
  # systemd.user.services.wallpaper-rotate = {
  #   description = "Đổi ảnh nền ngẫu nhiên (auto-rotate)";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "%h/.local/bin/wallpaper-set";
  #   };
  # };
  # systemd.user.timers.wallpaper-rotate = {
  #   description = "Đổi ảnh nền 30 phút kể từ lần đổi trước";
  #   timerConfig = { OnActiveSec = "30min"; AccuracySec = "1min"; };
  #   # KHÔNG wantedBy → không tự bật khi đăng nhập, phải start tay 1 lần.
  # };

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
