{ pkgs, config, ... }:

# RemNote AppImage: file ngoài Nix ở ~/Apps/RemNote/ (không nhúng vào build).
# Chi tiết: docs/REMNOTE.md. Dùng: tải file về ~/Downloads rồi `setup-remnote`.

{
  # (xdg.enable được bật tập trung tại entry point home/default.nix)

  # Cài appimage-run (công cụ chạy AppImage trên NixOS)
  home.packages = with pkgs; [
    appimage-run
  ];

  # Tạo desktop entry cho Rofi (exec cần đường dẫn tuyệt đối).
  xdg.desktopEntries.remnote = {
    name = "RemNote";
    comment = "RemNote note-taking app";
    exec = "appimage-run ${config.home.homeDirectory}/Apps/RemNote/RemNote.AppImage";
    terminal = false;
    type = "Application";
    categories = [
      "Office"
      "Utility"
    ];
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
    '';
  };
}
