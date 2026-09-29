{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wallpaper-set" = {
      executable = true;
      text = ''
          #! /usr/bin/env bash
          # wallpaper-set [đường-dẫn-ảnh|--if-empty] — đặt ảnh nền qua awww (fade 1.5s).
          # Chưa có ảnh nào (máy mới) → dùng ảnh mặc định trong repo, dự phòng
          # cuối là màu nền theme.
          set -u

          WALL_DIR="$HOME/Pictures/wallpapers"
          CACHE="$HOME/.cache/wallpaper-current"
          AWWW=${pkgs.awww}/bin/awww
          FALLBACK_COLOR="0x1e1e2eff" # nền Catppuccin Mocha — khi cả ảnh mặc định cũng hỏng
          # Cùng ảnh với lock-screen, trỏ thẳng store path (không copy ra ~/, không
          # phình thêm — ảnh này vốn đã nằm trong repo).
          DEFAULT_IMG=${./../../lockscreen/nixos.jpg}
          AWWW_IMG_ARGS=(-t fade --transition-duration 1.5)

          # realpath ảnh đang hiển thị: ưu tiên awww (chính xác), dự phòng cache.
          current_resolved() {
            local cur
            cur="$($AWWW query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)"
            [ -z "$cur" ] && cur="$(cat "$CACHE" 2>/dev/null || true)"
            # awww trả về hexcode (vd 0x1e1e2eff) khi nền là MÀU TRƠN, không phải
            # đường dẫn file — readlink -f sẽ ra rỗng và phá logic so sánh.
            case "$cur" in
              0x*) printf '%s\n' "$cur"; return 0 ;;
            esac
            [ -n "$cur" ] && readlink -f -- "$cur" 2>/dev/null
            return 0
          }

          # Bảo đảm daemon sống + sẵn sàng TRƯỚC (phải query được thì kiểm tra
          # ảnh hiện tại và --if-empty mới chính xác).
          systemctl --user start awww-daemon.service 2>/dev/null || true
          i=0
          while ! $AWWW query >/dev/null 2>&1; do
            i=$((i + 1))
            if [ "$i" -ge 40 ]; then
              notify-send -a wallpaper "wallpaper-set" "awww-daemon không phản hồi" 2>/dev/null || true
              exit 1
            fi
            sleep 0.25
          done

          # --if-empty (lúc đăng nhập): daemon đã tự khôi phục ảnh phiên trước từ
          # cache → giữ nguyên. Chờ ~1s cho ảnh kịp hiện; hết chờ vẫn trống thì rơi
          # xuống random bên dưới.
          if [ "''${1:-}" = "--if-empty" ]; then
            i=0
            while [ "$i" -lt 10 ]; do
              if $AWWW query 2>/dev/null | grep -q "currently displaying: image:"; then
                exit 0
              fi
              i=$((i + 1))
              sleep 0.1
            done
          fi

          img=""
          if [ "$#" -ge 1 ] && [ -f "$1" ]; then
            img="$1"
          else
            mapfile -t imgs < <(find "$WALL_DIR" -maxdepth 1 -xtype f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
            if [ "''${#imgs[@]}" -eq 0 ]; then
              # Máy mới / vừa xoá hết ảnh → ảnh mặc định trong repo, không có thì
              # rơi về màu nền theme.
              if [ -f "$DEFAULT_IMG" ]; then
                $AWWW img "$DEFAULT_IMG" "''${AWWW_IMG_ARGS[@]}"
                printf '%s\n' "$DEFAULT_IMG" > "$CACHE"
              else
                $AWWW img "$FALLBACK_COLOR" "''${AWWW_IMG_ARGS[@]}"
              fi
              notify-send -a wallpaper "wallpaper-set" \
                "Chưa có ảnh nền — tạm dùng ảnh mặc định. Thêm ảnh: mở yazi (\$mod+y) rồi copy vào Pictures/wallpapers" 2>/dev/null || true
              exit 0
            fi

            # Loại ảnh đang hiển thị khỏi danh sách → luôn đổi sang ảnh khác.
            cur="$(current_resolved)"
            cands=()
            for f in "''${imgs[@]}"; do
              if [ -n "$cur" ] && [ "$(readlink -f -- "$f")" = "$cur" ]; then continue; fi
              cands+=("$f")
            done
            if [ "''${#cands[@]}" -eq 0 ]; then
              cands=("''${imgs[@]}")
              if [ "''${#cands[@]}" -eq 1 ]; then
                notify-send -a wallpaper "wallpaper-set" "Chỉ có 1 ảnh trong $WALL_DIR" 2>/dev/null || true
              fi
            fi
            img="''${cands[$((RANDOM % ''${#cands[@]}))]}"
          fi

          # Đặt nền + ghi nhớ ảnh hiện tại.
          $AWWW img "$img" "''${AWWW_IMG_ARGS[@]}"
          printf '%s\n' "$img" > "$CACHE"
      '';
    };
  };
}
