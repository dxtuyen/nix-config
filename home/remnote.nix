{ pkgs, config, ... }:

# Module tích hợp RemNote (dưới dạng AppImage).
#
# Triết lý: RemNote là file "ngoài Nix" nằm ở ~/Apps/RemNote/, KHÔNG nhúng vào
# build để tránh làm chậm rebuild. Nix chỉ quản lý phần khung:
#   - appimage-run  : công cụ chạy AppImage (cài như gói)
#   - desktop entry : để Rofi/WOFI quét thấy "RemNote"
#   - update-remnote: script cập nhật AppImage từ file tải tay trong ~/Downloads
#
# Cách dùng:
#   - Tải RemNote-*.AppImage về ~/Downloads (tự tải từ trang chủ RemNote)
#   - Gõ `update-remnote` để cài/cập nhật
#   - Mở app: tìm "RemNote" trong Rofi/WOFI

{
  # Cần xdg.enable=true để home-manager tạo file .desktop trong ~/.local/share/applications
  xdg.enable = true;

  # Cài appimage-run (công cụ chạy AppImage trên NixOS)
  home.packages = with pkgs; [
    appimage-run
  ];

  # Tạo desktop entry cho Rofi/WOFI. exec dùng đường dẫn tuyệt đối
  # (vì trong file .desktop, `~` không được mở rộng).
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

  # Tạo script ~/.local/bin/update-remnote (thêm vào PATH ở home/default.nix)
  home.file.".local/bin/update-remnote" = {
    executable = true;
    text = ''
      #! /usr/bin/env bash
      set -euo pipefail

      # --- Cấu hình ---
      downloads="''${HOME}/Downloads"                  # nơi bạn tải AppImage thủ công
      apps_dir="''${HOME}/Apps/RemNote"                # thư mục chứa bản cài
      target="''${apps_dir}/RemNote.AppImage"          # file AppImage chính

      mkdir -p "$apps_dir"

      # Tìm file RemNote-*.AppImage mới nhất trong ~/Downloads (theo thời gian sửa)
      latest="$(find "$downloads" -maxdepth 1 -name 'RemNote-*.AppImage' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"
      if [ -z "$latest" ]; then
        echo "Không tìm thấy file RemNote-*.AppImage trong ''${downloads}." >&2
        echo "Hãy tải RemNote về ''${downloads} rồi chạy lại lệnh này." >&2
        exit 1
      fi

      # Nếu đã có bản cài, so hash hai file:
      #   giống nhau -> bản mới trùng bản cũ -> xóa file mới, không làm gì
      if [ -f "$target" ]; then
        local hashes
        hashes="$(sha256sum "$latest" "$target" | awk '{print $1}' | sort -u | wc -l)"
        if [ "$hashes" -eq 1 ]; then
          rm -f "$latest"
          echo "RemNote đã là phiên bản mới nhất, không cần cập nhật."
          exit 0
        fi
      fi

      # Khác nhau -> đè file cũ bằng file mới + cấp quyền thực thi
      mv -f "$latest" "$target"
      chmod +x "$target"
      echo "Đã cập nhật RemNote: $target"
    '';
  };
}
