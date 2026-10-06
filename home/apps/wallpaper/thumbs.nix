{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wallpaper-thumbs" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Build 320px Rofi thumbnails; --status prints the number missing.
        set -u
        WALL_DIR="$HOME/Pictures/wallpapers"
        THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
        mkdir -p "$HOME/.cache"

        # Grid and background builds can overlap when the menu opens repeatedly.
        # Hold one cache-wide lock until all ImageMagick workers have finished.
        if [ "''${WALLPAPER_THUMBS_LOCKED:-}" != 1 ]; then
          exec env WALLPAPER_THUMBS_LOCKED=1 ${pkgs.util-linux}/bin/flock \
            "$HOME/.cache/wallpaper-thumbs.lock" "$0" "$@"
        fi

        if [ ! -d "$WALL_DIR" ]; then
          [ "''${1:-}" = "--status" ] && echo 0
          exit 0
        fi

        missing=()
        while IFS= read -r -d $'\0' f; do
          t="$THUMB_DIR/''${f##*/}.thumb" # Use Bash parameter expansion.
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
          # Respect EXIF orientation and skip invalid images.
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
