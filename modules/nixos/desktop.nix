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

  # Thunar GIỮ LẠI: duyệt/xem/copy file + tích hợp GIO (mở file từ
  # Obsidian/Chrome…). Không khai báo `thunar` trong home.packages để tránh
  # bản user-level thiếu plugin đè lên package do NixOS module tạo ra.
  #
  # `tumbler` = dịch vụ ảnh thu nhỏ cho Thunar (không có nó thì chỉ có icon).
  # KHÔNG thêm thunar-archive-plugin (kéo file-roller → kéo cả GNOME stack)
  # và thunar-volman (mount USB thủ công theo docs/04) — xem docs/02.
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

  # Từ điển ngắt dòng (hyphenation) cho WebKitGTK — foliate dùng để `justify`
  # không bị "lỗ hổng" giữa các từ.
  #
  # ⚠️ Cài `hyphenDicts` thôi là KHÔNG ĐỦ. WebKitGTK hardcode 2 đường dẫn
  # (đã kiểm tra bằng `strings` trên libwebkitgtk-6.0.so.4):
  #     /usr/share/hyphen
  #     /usr/local/share/hyphen
  # và tự ghép tên file `hyph_<mã ngôn ngữ>.dic`. Trên NixOS hai đường dẫn đó
  # không tồn tại (/usr chỉ có /usr/bin/env) → WebKit im lặng, không ngắt từ.
  #
  # Cách sửa: trỏ symlink vào thư mục share/hyphen của gói trong store.
  # `L+` = tạo symlink (dấu + tạo cả thư mục cha nếu thiếu).
  # tmpfiles chạy lúc boot, nên đổi dict ở đây không cần rebuild app.
  #
  # Chỉ cài en_US: thư viện hiện có chủ yếu là sách tiếng Anh, và
  # nixpkgs `hyphenDicts` không có sẵn bộ tiếng Việt.
  # ⚠️ Module này không có `with pkgs` ở top-level (chỉ `with pkgs;` bên trong
  # list của `fonts.packages`) → phải gọi đủ `pkgs.`.
  systemd.tmpfiles.rules = [
    "L+/usr/share/hyphen - - - - ${pkgs.hyphenDicts.en_US}/share/hyphen"
  ];

  # ── Dọn thùng rác ──────────────────────────────────────────────────────────
  # Thùng rác GIO chứa ở ~/.local/share/Trash, hoạt động sẵn nhờ
  # `services.gvfs.enable` khai ở trên — không có option nào phải bật thêm.
  # Dùng bằng `d` trong yazi (xoá vĩnh viễn thì `D`), hoặc xem lại bằng `g t`.
  #
  # ⚠️ Timer là USER timer, KHÔNG phải system timer. `gio trash` cần
  # XDG_RUNTIME_DIR + DBUS_SESSION_BUS_ADDRESS; system timer thiếu 2 biến này
  # → lệnh hỏng mà không báo lỗi rõ ràng.
  systemd.user.services.trash-clean = {
    description = "Dọn thùng rác (giữ 30 ngày gần nhất)";
    # Script tự xoá cả file lẫn .trashinfo nên không cần gio trash --empty
    # (lệnh đó xoá sạch, mất luôn mục mới xoá lỡ → không kịp khôi phục).
    serviceConfig.ExecStart = "%h/.local/bin/trash-clean 30";
  };

  systemd.user.timers.trash-clean = {
    description = "Dọn thùng rác lúc 03:00 hằng ngày (xoá mục > 30 ngày)";
    # ⚠️ `systemd.user.timers` dùng tên option CỦA SYSTEMD GỐC (timerConfig.*),
    # không phải kiểu rút gọn như `systemd.timers` cấp hệ thống. Sai tên sẽ báo
    # "option does not exist" lúc build.
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      # ⭐ BẮT BUỘC: máy tắt lúc 3h (rất hay xảy ra — máy này dùng hibernate,
      # xem modules/nixos/laptop.nix) thì timer đó sẽ bị bỏ qua. Persistent=
      # chạy BÙ ngay khi bật máy lần sau. Thiếu nó → rác tích tụ vô hạn.
      Persistent = true;
      # Chỉ chạy sau khi session đồ hoạ đã lên (cần $XDG_RUNTIME_DIR cho gio).
      After = [ "graphical-session.target" ];
    };
    wantedBy = [ "timers.target" ];
  };

  # Gộp: khai chung khối systemd.user.services với fcitx5 để đọc gọn 1 chỗ.
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
