{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wallpaper-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # wallpaper-menu [auto|--grid|--list] — chọn ảnh nền trong
        # ~/Pictures/wallpapers. Ảnh đang đặt được đánh dấu "● " ở đầu tên.
        # Icon luôn là THUMBNAIL 320px, không dùng ảnh gốc (rofi decode ảnh gốc
        # mỗi lần mở → vài giây, RAM nhảy).
        #   auto (mặc định)  cache đủ thumbnail → lưới ảnh; còn thiếu → danh
        #                     sách chữ (mở tức thì) + tự dựng cache nền
        #   --grid           ép lưới ảnh (dựng cache trước nếu thiếu, có báo)
        #   --list           ép danh sách chữ, không icon (nhanh nhất, gõ lọc)
        set -u
        WALL_DIR="$HOME/Pictures/wallpapers"
        CACHE="$HOME/.cache/wallpaper-current"
        AWWW=${pkgs.awww}/bin/awww
        THUMB_DIR="$HOME/.cache/wallpaper-thumbs"

        mode="auto"
        case "''${1:-}" in
          --grid) mode="grid" ;;
          --list) mode="list" ;;
        esac

        # Ảnh hiện tại: đọc ~/.cache/wallpaper-current bằng `read` BUILTIN
        # (0 spawn) — wallpaper-set ghi file này mỗi lần đổi nên luôn đúng.
        # Chỉ hỏi awww khi cache trống (máy mới / chưa đổi lần nào).
        cur=""
        if [ -r "$CACHE" ]; then IFS= read -r cur < "$CACHE" || true; fi
        [ -z "$cur" ] && cur="$($AWWW query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)"
        # Nền MÀU TRƠN (awww trả hexcode 0x…) không phải đường dẫn file →
        # coi như chưa chọn ảnh nào.
        case "$cur" in
          0x*) cur="" ;;
          *) cur="$(readlink -f -- "''${cur:-}" 2>/dev/null || true)" ;;
        esac

        mapfile -t imgs < <(find "$WALL_DIR" -maxdepth 1 -xtype f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
        if [ "''${#imgs[@]}" -eq 0 ]; then
          notify-send -a wallpaper "wallpaper-menu" \
            "Chưa có ảnh nào trong $WALL_DIR — thêm bằng yazi (\$mod+y). Hiện đang dùng màu nền dự phòng."
          exit 0
        fi

        THUMBS="$HOME/.local/bin/wallpaper-thumbs"

        # Một vòng duy nhất, toàn builtin (bản cũ fork ~1000 lần ≈ 2.2s mỗi
        # lần mở). So sánh chuỗi trực tiếp: wallpaper symlink sẽ không gắn ●.
        #   sel/names/thumbs — index, tên (có "● "), thumbnail; missing = số
        #   thumb còn thiếu → chọn lưới/chữ ngay tại đây, không cần gọi
        #   `wallpaper-thumbs --status` riêng.
        sel=0
        missing=0
        i=0
        for f in "''${imgs[@]}"; do
          name="''${f##*/}"
          mark=""
          if [ -n "$cur" ] && [ "$f" = "$cur" ]; then mark="● "; sel=$i; fi
          t="$THUMB_DIR/$name.thumb"
          if [ ! -f "$t" ] || [ "$t" -ot "$f" ]; then
            t=""
            missing=$((missing + 1))
          fi
          names[i]="$mark$name"
          thumbs[i]="$t"
          i=$((i + 1))
        done

        # Chọn chế độ theo cache thumbnail:
        #   grid = icon = file 320px trong ~/.cache/wallpaper-thumbs
        #         (rofi KHÔNG decode ảnh gốc vài MB nữa → mở tức thì)
        #   list = chữ thuần, không icon (nhanh nhất, gõ để lọc)
        grid=0
        case "$mode" in
          list) ;;
          grid)
            if [ "$missing" -gt 0 ]; then
              notify-send -a wallpaper "wallpaper-menu" "Đang dựng thumbnail ($missing ảnh)…"
              "$THUMBS" >/dev/null 2>&1 || true
            fi
            grid=1 ;;
          auto)
            if [ "$missing" -eq 0 ]; then
              grid=1
            else
              # Lần đầu (hoặc vừa thêm ảnh): mở DANH SÁCH CHỮ ngay — không chờ
              # decode — dựng cache nền; lần mở sau tự thành lưới ảnh.
              nohup "$THUMBS" >/dev/null 2>&1 &
            fi ;;
        esac

        # Phím điều hướng: rofi mặc định gán Left/Right cho con trỏ trong ô
        # filter, nên không sang được cột 2, 3 của lưới. Đổi con trỏ sang
        # Alt+Left/Right, nhả Left/Right cho di chuyển cột. Alt+h/j/k/l và
        # Alt+u/i/o/p khớp keyd nav layer.
        kb=(
          -kb-move-char-back 'Alt+Left,Control+b'
          -kb-move-char-forward 'Alt+Right,Control+f'
          -kb-row-left 'Left,Alt+h'
          -kb-row-right 'Right,Alt+l'
          -kb-row-first 'Home,KP_Home,Alt+u'
          -kb-row-last 'End,KP_End,Alt+i'
          -kb-page-prev 'Page_Up,Alt+o'
          -kb-page-next 'Page_Down,Alt+p'
        )

        # -theme-str chỉ áp cho lần chạy này (không đụng ~/.config/rofi):
        # lưới 3 cột × 3 hàng, ảnh trên tên dưới, tên căn giữa.
        # cycle: vòng lại khi lưới hết ảnh thay vì kẹt ở ảnh cuối.
        if [ "$grid" -eq 1 ]; then
          rofi_args=(-dmenu -i -show-icons -l 3 -p '🖼️ Wallpaper'
            -mesg 'Enter: đặt nền · ←→↑↓: duyệt · ● = đang dùng · Esc: huỷ'
            -no-custom -format i -selected-row "$sel"
            "''${kb[@]}"
            -theme-str 'listview { columns: 3; spacing: 10px; flow: horizontal; cycle: true; }'
            -theme-str 'element { orientation: vertical; children: [element-icon, element-text]; padding: 6px; spacing: 6px; }'
            -theme-str 'element-icon { size: 10em; border-radius: 10px; }'
            -theme-str 'element-text { horizontal-align: center; }')
        else
          rofi_args=(-dmenu -i -l 10 -p '🖼️ Wallpaper'
            -mesg 'Enter: đặt nền · ↑↓: duyệt · ● = đang dùng · Esc: huỷ'
            -no-custom -format i -selected-row "$sel"
            "''${kb[@]}"
            -theme-str 'listview { cycle: true; }')
        fi

        # Mỗi mục: "<tên>\0icon\x1f<thumbnail>" → rofi tự bóc metadata.
        choice_idx="$(
          i=0
          while [ "$i" -lt "''${#imgs[@]}" ]; do
            if [ "$grid" -eq 1 ] && [ -n "''${thumbs[i]}" ]; then
              printf '%s\0icon\037%s\n' "''${names[i]}" "''${thumbs[i]}"
            else
              printf '%s\n' "''${names[i]}"
            fi
            i=$((i + 1))
          done | rofi "''${rofi_args[@]}"
        )" || exit 0

        if ! [[ "$choice_idx" =~ ^[0-9]+$ ]] || [ "$choice_idx" -ge "''${#imgs[@]}" ]; then exit 0; fi
        choice="''${imgs[$choice_idx]}"
        if [ "''${cur:-}" = "$(readlink -f -- "$choice")" ]; then
          notify-send -a wallpaper "wallpaper-menu" "Ảnh này đang là nền hiện tại"
          exit 0
        fi
        exec "$HOME/.local/bin/wallpaper-set" "$choice"
      '';
    };

    # Ảnh nền: cp/rm trực tiếp trong ~/Pictures/wallpapers, không cần rebuild.
  };
}
