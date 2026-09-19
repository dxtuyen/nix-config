{ pkgs, config, ... }:

# Module tích hợp RemNote (dưới dạng AppImage).
#
# Triết lý: RemNote là file "ngoài Nix" nằm ở ~/Apps/RemNote/, KHÔNG nhúng vào
# build để tránh làm chậm rebuild. Nix chỉ quản lý phần khung:
#   - appimage-run  : công cụ chạy AppImage (cài như gói)
#   - desktop entry : để Rofi/WOFI quét thấy "RemNote"
#   - setup-remnote : script cài AppImage từ file tải tay trong ~/Downloads
#
# Cách dùng (máy mới HOẶC khi có bản mới — y hệt nhau):
#   - Tải RemNote-*.AppImage về ~/Downloads (tự tải từ trang chủ RemNote)
#   - Gõ `setup-remnote` — script luôn ĐÈ bản cũ bằng file trong Downloads
#     (không so sánh hash; cập nhật nội dung note là việc của app)
#   - Mở app: tìm "RemNote" trong Rofi/WOFI

{
  # (xdg.enable được bật tập trung tại entry point home/default.nix)

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

  # Tạo script ~/.local/bin/setup-remnote (thêm vào PATH ở home/default.nix)
  home.file.".local/bin/setup-remnote" = {
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

      # Kiểm tra file hợp lệ trước khi cài (không phải thư mục, không rỗng)
      if [ ! -f "$latest" ] || [ ! -s "$latest" ]; then
        echo "Lỗi: File '$latest' không hợp lệ (không phải file hoặc rỗng)." >&2
        exit 1
      fi

      # Luôn đè bản cũ bằng file trong Downloads (không so sánh hash — đơn giản,
      # ai muốn giữ bản cũ thì tự copy trước). mv giữ nguyên file tải về,
      # chmod +x để chạy được.
      mv -f "$latest" "$target"
      chmod +x "$target"
      echo "Đã cài RemNote: $target"
    '';
  };
}
