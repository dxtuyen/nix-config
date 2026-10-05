{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wallpaper-set" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Set a wallpaper from a path or choose a random image.
        set -u

        WALL_DIR="$HOME/Pictures/wallpapers"
        CACHE="$HOME/.cache/wallpaper-current"
        AWWW=${pkgs.awww}/bin/awww
        FALLBACK_COLOR="0x1e1e2eff" # Catppuccin Mocha fallback color.
        # Reuse the lock-screen image directly from the Nix store.
        DEFAULT_IMG=${./../../lockscreen/nixos.jpg}
        AWWW_IMG_ARGS=(-t fade --transition-duration 1.5)

        # Resolve the current wallpaper, preferring awww's status.
        current_resolved() {
          local cur
          cur="$($AWWW query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)"
          [ -z "$cur" ] && cur="$(cat "$CACHE" 2>/dev/null || true)"
          # A hex value means the current background is a solid color.
          case "$cur" in
            0x*) printf '%s\n' "$cur"; return 0 ;;
          esac
          [ -n "$cur" ] && readlink -f -- "$cur" 2>/dev/null
          return 0
        }

        # Wait for the daemon before querying or setting the wallpaper.
        systemctl --user start awww-daemon.service 2>/dev/null || true
        i=0
        while ! $AWWW query >/dev/null 2>&1; do
          i=$((i + 1))
          if [ "$i" -ge 40 ]; then
            notify-send -a wallpaper "Wallpaper" "awww daemon is not responding." 2>/dev/null || true
            exit 1
          fi
          sleep 0.25
        done

        # On login, keep the image restored by the daemon; choose one if none appears.
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
            # Use the bundled image, then a solid theme color, when no images exist.
            if [ -f "$DEFAULT_IMG" ]; then
              $AWWW img "$DEFAULT_IMG" "''${AWWW_IMG_ARGS[@]}"
              printf '%s\n' "$DEFAULT_IMG" > "$CACHE"
            else
              $AWWW img "$FALLBACK_COLOR" "''${AWWW_IMG_ARGS[@]}"
            fi
            notify-send -a wallpaper "wallpaper-set" \
              "No wallpapers found. Using the fallback; add images to Pictures/wallpapers with Yazi (Mod+y)." 2>/dev/null || true
            exit 0
          fi

          # Prefer an image different from the current one.
          cur="$(current_resolved)"
          cands=()
          for f in "''${imgs[@]}"; do
            if [ -n "$cur" ] && [ "$(readlink -f -- "$f")" = "$cur" ]; then continue; fi
            cands+=("$f")
          done
          if [ "''${#cands[@]}" -eq 0 ]; then
            cands=("''${imgs[@]}")
            if [ "''${#cands[@]}" -eq 1 ]; then
              notify-send -a wallpaper "Wallpaper" "Only one image found in $WALL_DIR." 2>/dev/null || true
            fi
          fi
          img="''${cands[$((RANDOM % ''${#cands[@]}))]}"
        fi

        # Set and remember the selected wallpaper.
        $AWWW img "$img" "''${AWWW_IMG_ARGS[@]}"
        printf '%s\n' "$img" > "$CACHE"
      '';
    };
  };
}
