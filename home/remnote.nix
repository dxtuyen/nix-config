{ pkgs, config, ... }:

# RemNote AppImage: file ngoài Nix ở ~/Apps/RemNote/ (không nhúng vào build).
# Chi tiết: docs/REMNOTE.md. Dùng: tải file về ~/Downloads rồi `setup-remnote`.

{
  # (xdg.enable được bật tập trung tại entry point home/default.nix)

  # Công cụ chạy AppImage + trích icon.
  #   appimage-run        — chạy app (desktop entry dùng đường dẫn tuyệt đối)
  #   squashfsTools       — unsquashfs, trích ĐÚNG 1 file icon trong ~9ms
  #   desktop-file-utils  — update-desktop-database (Rofi/GIO đọc app list)
  home.packages = with pkgs; [
    appimage-run
    squashfsTools
    desktop-file-utils
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
      # setup-remnote — cài/cập nhật RemNote AppImage + trích icon cho Rofi.
      # Dùng chung cho: máy mới · cài lại · cập nhật bản mới.
      # Chi tiết + xử lý sự cố: docs/REMNOTE.md
      set -euo pipefail

      downloads="''${HOME}/Downloads"
      apps_dir="''${HOME}/Apps/RemNote"
      target="$apps_dir/RemNote.AppImage"

      UNSQUASHFS=${pkgs.squashfsTools}/bin/unsquashfs
      UPDATE_DESKTOP_DB=${pkgs.desktop-file-utils}/bin/update-desktop-database
      apps_root="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"

      # ── 1. Tìm file mới nhất trong ~/Downloads ──────────────────────────
      # Duyệt bằng glob (không `find | sort | head`) vì `head -n1` cho SIGPIPE
      # làm `set -o pipefail` + `set -e` giết script IM LẶNG. So sánh mtime bằng
      # `-nt` của bash, không cần sort.
      latest=""
      for f in "$downloads"/RemNote-*.AppImage "$downloads"/remnote-*.AppImage; do
        [[ -f "$f" ]] || continue
        if [[ -z "$latest" || "$f" -nt "$latest" ]]; then latest="$f"; fi
      done
      if [[ -z "$latest" ]]; then
        echo "Không tìm thấy file RemNote-*.AppImage trong $downloads." >&2
        echo "Hãy tải RemNote về $downloads rồi chạy lại lệnh này." >&2
        exit 1
      fi

      # ── 2. Kiểm tra hợp lệ TRƯỚC khi ghi đè bản đang chạy ───────────────
      if [[ ! -s "$latest" ]]; then
        echo "Lỗi: '$latest' rỗng hoặc không phải file — tải lại nhé." >&2
        exit 1
      fi
      # AppImage type 2 = ELF, đúng 3 byte magic nằm ở offset 8: AI + \x02.
      # Cắt 1 file .AppImage bị hỏng giữa chừng vẫn có dung lượng nhưng vô dụng.
      magic="$(head -c 11 "$latest" | tail -c 3)"
      if [[ "$magic" != $'AI\x02' ]]; then
        echo "Lỗi: '$latest' không phải AppImage hợp lệ (magic sai)." >&2
        echo "Có thể tải dở hoặc file hỏng — tải lại từ trang chủ RemNote." >&2
        exit 1
      fi

      # Cài bản mới vào file TẠM trước. Nếu mọi thứ sau đó hỏng (chmod, giải
      # nén…), bản cũ vẫn nguyên — không để lại ~/Apps/RemNote hỏng giữa chừng.
      mkdir -p "$apps_dir"
      staged="$apps_dir/.RemNote.AppImage.tmp.$$"
      mv -f "$latest" "$staged"
      chmod +x "$staged"

      # ── 3. Trích icon: unsquashfs đọc squashfs, KHÔNG giải nén 207MB ──────
      # AppImage type 2 = ELF header + squashfs image. `AppImage --appimage-extract`
      # phải bung TOÀN BỘ image ra đĩa (~500MB–1GB, vài giây) chỉ để lấy 1 file.
      # `unsquashfs -o <offset> <file> <đường-dẫn>` chỉ trích đúng file cần: ~9ms.
      icon_dir="''${HOME}/.local/share/icons/hicolor/512x512/apps"
      icon_file="$icon_dir/remnote.png"
      icon_in_appimage='usr/share/icons/hicolor/0x0/apps/remnote.png'

      offset="$("$staged" --appimage-offset 2>/dev/null || echo "")"

      # Kiểm tra squashfs CÓ nguyên vẹn không. Magic bytes ở offset 8 nằm trong
      # ELF header, nên file BỊ CẮT DỒI (tải dở, hết mạng) vẫn qua kiểm tra đó —
      # rồi đè lên bản đang chạy bằng một file không bao giờ chạy được.
      # `unsquashfs -s` đọc superblock (nằm ở CUỐI file) nên báo lỗi ngay.
      if [[ -z "$offset" ]] || ! "$UNSQUASHFS" -o "$offset" -s "$staged" >/dev/null 2>&1; then
        echo "Lỗi: AppImage bị cắt cụt hoặc hỏng — không đọc được squashfs." >&2
        echo "Bản cũ vẫn giữ nguyên. Hãy tải lại từ trang chủ RemNote." >&2
        rm -f "$staged"
        exit 1
      fi

      tmp="$(mktemp -d)"
      # trap dọn tạm DÙ thành công, lỗi, hay Ctrl-C — bản cũ dùng `rm -rf` ở
      # cuối nên `set -e` làm sót lại hàng trăm MB trong /tmp khi hỏng giữa chừng.
      trap 'rm -f "$staged"; rm -rf "$tmp"' EXIT

      if [[ -n "$offset" ]] && "$UNSQUASHFS" -o "$offset" -d "$tmp" "$staged" \
        "$icon_in_appimage" >/dev/null 2>&1 &&
        [[ -f "$tmp/$icon_in_appimage" ]]; then
        mkdir -p "$icon_dir"
        install -m 644 "$tmp/$icon_in_appimage" "$icon_file"
        echo "Đã cài icon: $icon_file"
      else
        # AppImage mới đổi cấu trúc bên trong → bỏ qua, app vẫn chạy bình thường.
        echo "Cảnh báo: không tìm thấy icon '$icon_in_appimage' trong AppImage." >&2
        echo "Rofi có thể hiện RemNote không icon." >&2
      fi

      # ── 4. Ghi đè bản cũ — nhưng GIỮ LẠI 1 bản `.bak` ─────────────────────
      # `mv` trong cùng thư mục = rename nên gần như tức thì với file 207MB
      # (khác với `cp` phải chép hết). Bản cũ đổi tên thành `.bak` trước, nên
      # nếu bản mới có vấn đề lúc chạy thì vẫn quay lại được bằng:
      #   mv ~/Apps/RemNote/RemNote.AppImage.bak ~/Apps/RemNote/RemNote.AppImage
      if [[ -f "$target" ]]; then
        mv -f "$target" "$target.bak"
      fi
      mv -f "$staged" "$target"
      trap - EXIT
      rm -rf "$tmp"
      echo "Đã cài RemNote: $target"
      [[ -f "$target.bak" ]] && echo "Bản cũ giữ lại: $target.bak"

      # Báo cho GIO/desktop-database biết app list đã đổi (Rofi, Thunar menu).
      [[ -d "$apps_root" ]] && "$UPDATE_DESKTOP_DB" "$apps_root" 2>/dev/null || true
    '';
  };
}
