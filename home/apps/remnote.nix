{ pkgs, config, ... }:

# RemNote AppImage: file ngoài Nix ở ~/Apps/RemNote/ (không nhúng vào build).
# Dùng: tải file về ~/Downloads rồi `setup-remnote`. Chi tiết: docs/REMNOTE.md.

{
  # Công cụ chạy AppImage + trích icon: appimage-run · squashfsTools (unsquashfs)
  # · desktop-file-utils (update-desktop-database, Rofi/GIO đọc app list).
  home.packages = with pkgs; [
    appimage-run
    squashfsTools
    desktop-file-utils
  ];

  # Tạo desktop entry cho Rofi. `exec` dùng ĐƯỜNG DẪN TUYỆT ĐỐI: Rofi loại bỏ
  # entry khi không tìm thấy binary trong PATH.
  xdg.desktopEntries.remnote = {
    name = "RemNote";
    comment = "RemNote note-taking app";
    exec = "${pkgs.appimage-run}/bin/appimage-run ${config.home.homeDirectory}/Apps/RemNote/RemNote.AppImage";

    # Icon do `setup-remnote` trích từ AppImage; trỏ đường dẫn TUYỆT ĐỐI để
    # không phụ thuộc icon theme/cache của GTK.
    icon = "${config.home.homeDirectory}/.local/share/icons/hicolor/512x512/apps/remnote.png";

    terminal = false;
    type = "Application";

    categories = [
      "Office"
      "Utility"
    ];

    # Lấy từ .desktop gốc trong AppImage: window map đúng icon/app khi nhóm cửa sổ.
    settings.StartupWMClass = "RemNote";
  };
}
