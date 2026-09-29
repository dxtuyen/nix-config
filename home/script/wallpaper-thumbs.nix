{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wallpaper-thumbs" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # wallpaper-thumbs [--status] — dựng thumbnail 320px cho rofi vào
        # ~/.cache/wallpaper-thumbs/<tên>.thumb. `--status` chỉ in số thumbnail
        # còn thiếu. Xoá thư mục cache → tự dựng lại. 8 luồng ImageMagick.
        set -u
        WALL_DIR="$HOME/Pictures/wallpapers"
        THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
  
        if [ ! -d "$WALL_DIR" ]; then
          [ "''${1:-}" = "--status" ] && echo 0
          exit 0
        fi
  
        missing=()
        while IFS= read -r -d $'\0' f; do
          t="$THUMB_DIR/''${f##*/}.thumb"  # builtin — không fork basename
          [ -f "$t" ] && [ "$t" -nt "$f" ] && continue
          missing+=("$f")
        done < <(find "$WALL_DIR" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0 2>/dev/null)
  
        if [ "''${1:-}" = "--status" ]; then
          echo "''${#missing[@]}"
          exit 0
        fi
        [ "''${#missing[@]}" -eq 0 ] && exit 0
  
        mkdir -p "$THUMB_DIR"
        make_thumb() {
          # -auto-orient: ảnh điện thoại xoay theo EXIF; -thumbnail 320x320:
          # vừa khung 10em của rofi. Ảnh hỏng → bỏ qua (menu tự hiện tên chữ).
          ${pkgs.imagemagick}/bin/magick "$1" -auto-orient -thumbnail 320x320 \
            -quality 80 "$THUMB_DIR/''${1##*/}.thumb" 2>/dev/null || true
        }
        export -f make_thumb
        export THUMB_DIR
        printf '%s\0' "''${missing[@]}" | xargs -0 -P 8 -I{} bash -c 'make_thumb "$@"' _ {}
      '';
    };
  };
}
