{ ... }:

{
  home.file = {
    ".local/bin/trash-clean" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Dọn thùng rác GIO, giữ lại N ngày gần nhất (không dùng
        # `gio trash --empty` — xoá sạch, mất luôn mục vừa xoá lỡ).
        # Xoá cả file lẫn .trashinfo: .trashinfo mồ côi làm gio/yazi báo
        # "trash hỏng".
        set -u

        # Mặc định 30 ngày: thùng rác là vùng an toàn, khôi phục bằng `g t` trong
        # yazi. Đổi số ở ExecStart trong modules/nixos/desktop.nix.
        KEEP_DAYS="''${1:-30}"
        TRASH_DIR="''$HOME/.local/share/Trash"
        FILES_DIR="$TRASH_DIR/files"
        INFO_DIR="$TRASH_DIR/info"

        [ -d "$INFO_DIR" ] || exit 0

        # Mốc cắt: mốc CŨ HƠN mốc này thì bị xoá. So sánh chuỗi ngày
        # YYYY-MM-DD thì đúng theo thứ tự (zero-padded) nên không cần date.
        CUTOFF="$(date -d "''${KEEP_DAYS} days ago" +%Y-%m-%d)"

        removed=0
        kept=0
        for info in "$INFO_DIR"/*.trashinfo; do
          [ -e "$info" ] || continue

          # DeletionDate trong .trashinfo là ISO: 2026-09-08T11:16:25
          date="''$(sed -n 's/^DeletionDate=//p' "$info" | head -1 | cut -dT -f1)"
          [ -n "$date" ] || date="$(date +%Y-%m-%d)" # thiếu dữ liệu → coi như mới

          if [[ "$date" < "$CUTOFF" ]]; then
            base="''${info##*/}"
            base="''${base%.trashinfo}"
            # rm -rf: mục có thể là thư mục. -f để không lỗi nếu đã mất.
            rm -rf -- "$FILES_DIR/$base" "$info" 2>/dev/null || true
            removed=$((removed + 1))
          else
            kept=$((kept + 1))
          fi
        done

        echo "thung rac: giu $kept muc (<= $KEEP_DAYS ngay), da xoa $removed muc (< $CUTOFF)"

        # Cảnh báo nếu còn rác nhiều (để biết nên tăng KEEP_DAYS).
        size="''$(du -sh "$FILES_DIR" 2>/dev/null | cut -f1)"
        if [ "''${size:-0}" != "0" ] && [ -n "''${size:-}" ]; then
          echo "dung luong con lai trong thung rac: $size"
        fi
      '';
    };
  };
}
