{ pkgs, config, ... }:

# Module tích hợp RemNote (dưới dạng AppImage).
#
# Triết lý: RemNote là file "ngoài Nix" nằm ở ~/Apps/RemNote/, KHÔNG nhúng vào
# build để tránh làm chậm rebuild. Nix chỉ quản lý phần khung:
#   - appimage-run  : công cụ chạy AppImage (cài như gói)
#   - desktop entry : để Rofi/WOFI quét thấy "RemNote"
#   - update-remnote: script tự cập nhật AppImage
#
# Cách dùng:
#   - Cài/cập nhật: gõ `update-remnote`
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
      downloads="''${HOME}/Downloads"                  # nơi bạn tải AppImage thủ công (nếu có)
      apps_dir="''${HOME}/Apps/RemNote"                # thư mục chứa bản cài
      target="''${apps_dir}/RemNote.AppImage"          # file AppImage chính
      url="https://backend.remnote.com/desktop/linux"  # URL tải bản mới (nếu đổi, sửa ở đây)

      mkdir -p "$apps_dir"

      # Hàm cài một file AppImage (từ ~/Downloads hoặc vừa tải về) vào vị trí chính
      install_file() {
        local src="$1"
        # Nếu đã có bản cài, so hash hai file:
        #   giống nhau -> bản mới trùng bản cũ -> xóa file mới, không làm gì
        if [ -f "$target" ]; then
          local hashes
          hashes="$(sha256sum "$src" "$target" | awk '{print $1}' | sort -u | wc -l)"
          if [ "$hashes" -eq 1 ]; then
            rm -f "$src"
            echo "RemNote đã là phiên bản mới nhất, không cần cập nhật."
            exit 0
          fi
        fi
        # Khác nhau -> đè file cũ bằng file mới + cấp quyền thực thi
        mv -f "$src" "$target"
        chmod +x "$target"
        echo "Đã cập nhật RemNote: $target"
      }

      # --- Bước 1: Ưu tiên dùng file bạn tự tải trong ~/Downloads ---
      # Tìm file RemNote-*.AppImage mới nhất (theo thời gian sửa), nếu có thì dùng luôn
      latest="$(find "$downloads" -maxdepth 1 -name 'RemNote-*.AppImage' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"
      if [ -n "$latest" ]; then
        install_file "$latest"
        exit 0
      fi

      # --- Bước 2: So nội dung thật với bản đang cài (tải 1MB đầu, ~rất nhanh) ---
      # Dùng HTTP Range: server chỉ gửi 1MB đầu file. So hash 1MB này với 1MB đầu
      # của bản đang cài -> nếu giống nhau là cùng phiên bản (không cần tải cả file).
      # Lưu ý: Nếu chưa có bản cài (target không tồn tại) -> bỏ qua so sánh, tải luôn.
      remote_head=""
      if [ -f "$target" ]; then
        local_head="$(head -c 1048576 "$target" | sha256sum | awk '{print $1}')"
        echo "Kiểm tra phiên bản RemNote mới nhất từ ''${url} ..."
        remote_head="$(curl -fsL --retry 2 --max-time 20 -r 0-1048575 "$url" 2>/dev/null | sha256sum | awk '{print $1}')"
        if [ -n "$remote_head" ] && [ "$remote_head" = "$local_head" ]; then
          echo "RemNote đã là phiên bản mới nhất, không cần cập nhật."
          exit 0
        fi
      fi

      # --- Bước 3: Tải bản mới (hoặc báo tải tay khi không có mạng) ---
      # remote_head rỗng khi: có mạng nhưng chưa có bản cài (tải luôn),
      # hoặc không lấy được 1MB (mất mạng / link hỏng -> báo tải tay).
      if [ -z "$remote_head" ] && [ -f "$target" ]; then
        echo "Không có mạng, không kiểm tra được phiên bản mới." >&2
        echo "Hãy tải tay file RemNote-*.AppImage về ''${downloads} rồi chạy lại lệnh này." >&2
        exit 1
      fi

      # Tải vào file tạm (không ghi đè trực tiếp bản đang dùng, đề phòng tải lỗi giữa chừng)
      tmp="''${apps_dir}/.RemNote.AppImage.download"
      echo "Có phiên bản mới, đang tải đầy đủ từ ''${url} ..."
      if ! curl -fL --retry 2 -o "$tmp" "$url"; then
        rm -f "$tmp"
        echo "Lỗi: Tải thất bại." >&2
        echo "Nếu link tải đã đổi, hãy tải tay file RemNote-*.AppImage về ''${downloads} rồi chạy lại lệnh này." >&2
        exit 1
      fi
      # Cài file vừa tải về
      install_file "$tmp"
    '';
  };
}
