{ pkgs, config, ... }:

# RemNote AppImage: file ngoài Nix ở ~/Apps/RemNote/ (không nhúng vào build).
# Chi tiết: docs/REMNOTE.md. Dùng: tải file về ~/Downloads rồi `setup-remnote`.

{
  # (xdg.enable được bật tập trung tại entry point home/default.nix)

  # Cài appimage-run (công cụ chạy AppImage trên NixOS)
  home.packages = with pkgs; [
    appimage-run
  ];

  # Tạo desktop entry cho Rofi.
  # `exec` dùng ĐƯỜNG DẪN TUYỆT ĐỐI: Rofi loại bỏ entry khi không tìm thấy
  # binary trong PATH (session sway không có ~/.local/bin trong PATH).
  xdg.desktopEntries.remnote = {
    name = "RemNote";
    comment = "RemNote note-taking app";
    exec = "${pkgs.appimage-run}/bin/appimage-run ${config.home.homeDirectory}/Apps/RemNote/RemNote.AppImage";
    # Icon nằm ở ~/.local/share/icons/hicolor/512x512/apps/remnote.png, do
    # `setup-remnote` trích ra từ AppImage (AppImage chỉ có thư mục size 0x0 —
    # GTK không đọc size này nên copy nguyên vẫn không hiện).
    # Trỏ ĐƯỜNG DẪN TUYỆT ĐỐI thay vì tên icon: không phụ thuộc icon theme
    # (đang dùng Papirus-Dark) và không phụ thuộc icon cache của GTK.
    icon = "${config.home.homeDirectory}/.local/share/icons/hicolor/512x512/apps/remnote.png";
    terminal = false;
    type = "Application";
    categories = [
      "Office"
      "Utility"
    ];
    # Lấy từ .desktop gốc trong AppImage: để window map đúng icon/app khi
    # nhóm cửa sổ (sway/waybar) và các launcher khác.
    settings.StartupWMClass = "RemNote";
  };

  # Script cài AppImage từ ~/Downloads (PATH thêm ở home/default.nix).
  home.file.".local/bin/setup-remnote" = {
    executable = true;
    text = ''
      #! /usr/bin/env bash
      set -euo pipefail

      downloads="''${HOME}/Downloads"
      apps_dir="''${HOME}/Apps/RemNote"
      target="''${apps_dir}/RemNote.AppImage"

      mkdir -p "$apps_dir"

      # File mới nhất trong ~/Downloads (theo thời gian sửa).
      latest="$(find "$downloads" -maxdepth 1 -name 'RemNote-*.AppImage' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"
      if [ -z "$latest" ]; then
        echo "Không tìm thấy file RemNote-*.AppImage trong ''${downloads}." >&2
        echo "Hãy tải RemNote về ''${downloads} rồi chạy lại lệnh này." >&2
        exit 1
      fi

      # File phải tồn tại và không rỗng.
      if [ ! -f "$latest" ] || [ ! -s "$latest" ]; then
        echo "Lỗi: File '$latest' không hợp lệ (không phải file hoặc rỗng)." >&2
        exit 1
      fi

      # Luôn đè bản cũ (không so hash).
      mv -f "$latest" "$target"
      chmod +x "$target"
      echo "Đã cài RemNote: $target"

      # Trích icon từ AppImage ra ~/.local/share/icons.
      # Bắt buộc vì AppImage chỉ đặt icon ở thư mục size KHÔNG chuẩn
      # (hicolor/0x0) — GTK chỉ đọc 16/24/32/48/64/128/256/512 nên copy
      # nguyên thư mục cũng không hiện icon trong Rofi.
      icon_dir="''${HOME}/.local/share/icons/hicolor/512x512/apps"
      icon_file="''${icon_dir}/remnote.png"
      icon_in_appimage='usr/share/icons/hicolor/0x0/apps/remnote.png'

      tmp="$(mktemp -d)"
      if (cd "$tmp" && "$target" --appimage-extract "$icon_in_appimage" >/dev/null 2>&1) &&
         [ -f "$tmp/squashfs-root/$icon_in_appimage" ]; then
        mkdir -p "$icon_dir"
        install -m 644 "$tmp/squashfs-root/$icon_in_appimage" "$icon_file"
        echo "Đã cài icon: $icon_file"
      else
        # AppImage đổi cấu trúc bên trong → bỏ qua, app vẫn chạy bình thường.
        echo "Cảnh báo: không tìm thấy icon '$icon_in_appimage' trong AppImage." >&2
        echo "Rofi có thể hiện RemNote không icon." >&2
      fi
      rm -rf "$tmp"
    '';
  };
}
