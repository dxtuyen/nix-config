{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wallpaper-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Choose a wallpaper from ~/Pictures/wallpapers.
        # auto uses a grid when thumbnails are ready; --grid and --list force a layout.
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

        # Read the cached current image; query awww only if the cache is empty.
        cur=""
        if [ -r "$CACHE" ]; then IFS= read -r cur < "$CACHE" || true; fi
        [ -z "$cur" ] && cur="$($AWWW query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)"
        # Ignore solid-color backgrounds when comparing image paths.
        case "$cur" in
          0x*) cur="" ;;
          *) cur="$(readlink -f -- "''${cur:-}" 2>/dev/null || true)" ;;
        esac

        mapfile -t imgs < <(find "$WALL_DIR" -maxdepth 1 -xtype f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort)
        if [ "''${#imgs[@]}" -eq 0 ]; then
          notify-send -a wallpaper "wallpaper-menu" \
            "No images in $WALL_DIR. Add some with Yazi (Mod+y). Using the fallback color."
          exit 0
        fi

        THUMBS="$HOME/.local/bin/wallpaper-thumbs"

        # Build the menu data in one pass and count missing thumbnails.
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

        # Use the grid when thumbnails are available; otherwise use a text list.
        grid=0
        case "$mode" in
          list) ;;
          grid)
            if [ "$missing" -gt 0 ]; then
              notify-send -a wallpaper "Wallpaper" "Building $missing thumbnails…"
              "$THUMBS" >/dev/null 2>&1 || true
            fi
            grid=1 ;;
          auto)
            if [ "$missing" -eq 0 ]; then
              grid=1
            else
              # Open the text list immediately while thumbnails build in the background.
              nohup "$THUMBS" >/dev/null 2>&1 &
            fi ;;
        esac

        # Navigation keys: rofi by default binds Left/Right to the cursor inside
        # the filter box, so you cannot reach column 2/3 of the grid. Move the
        # cursor to Alt+Left/Right and free Left/Right for column movement.
        # Alt+h/j/k/l and Alt+u/i/o/p are mnemonic (hjkl + edges), matching the
        # old keyd nav layer (keyd no longer remaps Tab).
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

        # Apply a three-column grid theme to this Rofi invocation only.
        if [ "$grid" -eq 1 ]; then
          rofi_args=(-dmenu -i -show-icons -l 3 -p '🖼️ Wallpaper'
            -mesg 'Enter: set · arrows: navigate · ●: current · Esc: cancel'
            -no-custom -format i -selected-row "$sel"
            "''${kb[@]}"
            -theme-str 'listview { columns: 3; spacing: 10px; flow: horizontal; cycle: true; }'
            -theme-str 'element { orientation: vertical; children: [element-icon, element-text]; padding: 6px; spacing: 6px; }'
            -theme-str 'element-icon { size: 10em; border-radius: 10px; }'
            -theme-str 'element-text { horizontal-align: center; }')
        else
          rofi_args=(-dmenu -i -l 10 -p '🖼️ Wallpaper'
            -mesg 'Enter: set · ↑↓: navigate · ●: current · Esc: cancel'
            -no-custom -format i -selected-row "$sel"
            "''${kb[@]}"
            -theme-str 'listview { cycle: true; }')
        fi

        # Pass each item and its thumbnail to Rofi as entry metadata.
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
          notify-send -a wallpaper "Wallpaper" "This image is already selected."
          exit 0
        fi
        exec "$HOME/.local/bin/wallpaper-set" "$choice"
      '';
    };

    # Add or remove wallpapers directly in ~/Pictures/wallpapers.
  };
}
