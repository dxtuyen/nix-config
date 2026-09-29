{ pkgs, ... }:

{
  home.file = {
    ".local/bin/setup-remnote" = {
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
        # Duyệt bằng glob thay vì find | sort | head để tránh SIGPIPE với pipefail.
        latest=""

        for f in "$downloads"/RemNote-*.AppImage "$downloads"/remnote-*.AppImage; do
          [[ -f "$f" ]] || continue

          if [[ -z "$latest" || "$f" -nt "$latest" ]]; then
            latest="$f"
          fi
        done

        if [[ -z "$latest" ]]; then
          echo "Không tìm thấy file RemNote-*.AppImage trong $downloads." >&2
          echo "Hãy tải RemNote về $downloads rồi chạy lại lệnh này." >&2
          exit 1
        fi

        # ── 2. Kiểm tra AppImage trước khi thay bản đang chạy ───────────────

        if [[ ! -s "$latest" ]]; then
          echo "Lỗi: '$latest' rỗng hoặc không phải file — tải lại nhé." >&2
          exit 1
        fi

        # AppImage type 2 = ELF + AI\x02.
        magic="$(head -c 11 "$latest" | tail -c 3)"

        if [[ "$magic" != $'AI\x02' ]]; then
          echo "Lỗi: '$latest' không phải AppImage hợp lệ (magic sai)." >&2
          echo "Có thể tải dở hoặc file hỏng — tải lại từ trang chủ RemNote." >&2
          exit 1
        fi

        # Đưa bản mới vào file tạm trong cùng thư mục: nếu bước kiểm tra hoặc trích
        # icon thất bại, bản đang chạy vẫn nguyên.
        mkdir -p "$apps_dir"

        staged="$apps_dir/.RemNote.AppImage.tmp.$$"

        mv -f "$latest" "$staged"
        chmod +x "$staged"

        # ── 3. Kiểm tra SquashFS + trích icon ───────────────────────────────
        # Không dùng `--appimage-extract` (giải nén toàn bộ image); unsquashfs
        # chỉ trích đúng file icon.

        icon_dir="''${HOME}/.local/share/icons/hicolor/512x512/apps"
        icon_file="$icon_dir/remnote.png"
        icon_in_appimage='usr/share/icons/hicolor/0x0/apps/remnote.png'

        offset="$("$staged" --appimage-offset 2>/dev/null || echo "")"

        # Kiểm tra superblock SquashFS nằm ở cuối file: AppImage bị tải dở/cắt cụt
        # sẽ bị phát hiện trước khi thay thế bản đang chạy.
        if [[ -z "$offset" ]] ||
           ! "$UNSQUASHFS" -o "$offset" -s "$staged" >/dev/null 2>&1; then

          echo "Lỗi: AppImage bị cắt cụt hoặc hỏng — không đọc được squashfs." >&2
          echo "Bản đang chạy vẫn giữ nguyên." >&2

          rm -f "$staged"
          exit 1
        fi

        tmp="$(mktemp -d)"

        # Dọn file tạm khi thành công, lỗi hoặc Ctrl-C.
        trap 'rm -f "$staged"; rm -rf "$tmp"' EXIT

        if "$UNSQUASHFS" -o "$offset" -d "$tmp" "$staged" \
          "$icon_in_appimage" >/dev/null 2>&1 &&
          [[ -f "$tmp/$icon_in_appimage" ]]; then

          mkdir -p "$icon_dir"

          install -m 644 \
            "$tmp/$icon_in_appimage" \
            "$icon_file"

          echo "Đã cài icon: $icon_file"

        else
          # AppImage mới đổi cấu trúc bên trong → app vẫn chạy bình thường.
          echo "Cảnh báo: không tìm thấy icon '$icon_in_appimage' trong AppImage." >&2
          echo "Rofi có thể hiện RemNote không icon." >&2
        fi

        # ── 4. Cài bản mới ─────────────────────────────────────────────────
        # Không giữ .bak: bản cũ bị thay sau khi bản mới vượt toàn bộ kiểm tra.
        mv -f "$staged" "$target"

        trap - EXIT
        rm -rf "$tmp"

        echo "Đã cài RemNote: $target"

        # Báo cho GIO/desktop database biết app list đã đổi.
        [[ -d "$apps_root" ]] &&
          "$UPDATE_DESKTOP_DB" "$apps_root" 2>/dev/null || true
      '';
    };
  };
}
