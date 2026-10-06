{ pkgs, ... }:

{
  home.file = {
    ".local/bin/setup-remnote" = {
      executable = true;

      text = ''
        #! /usr/bin/env bash

        # Install or update the RemNote AppImage and Rofi icon.

        set -euo pipefail

        downloads="''${HOME}/Downloads"
        apps_dir="''${HOME}/Apps/RemNote"
        target="$apps_dir/RemNote.AppImage"

        UNSQUASHFS=${pkgs.squashfsTools}/bin/unsquashfs
        UPDATE_DESKTOP_DB=${pkgs.desktop-file-utils}/bin/update-desktop-database
        apps_root="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"

        # Find the newest AppImage in Downloads.
        latest=""

        for f in "$downloads"/RemNote-*.AppImage "$downloads"/remnote-*.AppImage; do
          [[ -f "$f" ]] || continue

          if [[ -z "$latest" || "$f" -nt "$latest" ]]; then
            latest="$f"
          fi
        done

        if [[ -z "$latest" ]]; then
          echo "No RemNote-*.AppImage found in $downloads." >&2
          echo "Download RemNote there and run this command again." >&2
          exit 1
        fi

        # Validate the new image before replacing the installed version.

        if [[ ! -s "$latest" ]]; then
          echo "Error: '$latest' is empty or is not a file. Download it again." >&2
          exit 1
        fi

        # AppImage type 2 = ELF + AI\x02.
        magic="$(head -c 11 "$latest" | tail -c 3)"

        if [[ "$magic" != $'AI\x02' ]]; then
          echo "Error: '$latest' is not a valid AppImage (invalid magic bytes)." >&2
          echo "It may be incomplete or corrupted. Download it again from RemNote." >&2
          exit 1
        fi

        # Use a temporary file so failures leave the installed version untouched.
        mkdir -p "$apps_dir"

        staged="$apps_dir/.RemNote.AppImage.tmp.$$"

        mv -f "$latest" "$staged"
        chmod +x "$staged"

        # Validate the SquashFS image and extract only the icon.

        icon_dir="''${HOME}/.local/share/icons/hicolor/512x512/apps"
        icon_file="$icon_dir/remnote.png"
        icon_in_appimage='usr/share/icons/hicolor/0x0/apps/remnote.png'

        offset="$("$staged" --appimage-offset 2>/dev/null || echo "")"

        # Detect truncated downloads before replacing the installed version.
        if [[ -z "$offset" ]] ||
           ! "$UNSQUASHFS" -o "$offset" -s "$staged" >/dev/null 2>&1; then

          echo "Error: AppImage is truncated or corrupted; SquashFS is unreadable." >&2
          echo "The installed version was left unchanged." >&2

          rm -f "$staged"
          exit 1
        fi

        tmp="$(mktemp -d)"

        # Remove temporary files on success, failure, or interruption.
        trap 'rm -f "$staged"; rm -rf "$tmp"' EXIT

        if "$UNSQUASHFS" -o "$offset" -d "$tmp" "$staged" \
          "$icon_in_appimage" >/dev/null 2>&1 &&
          [[ -f "$tmp/$icon_in_appimage" ]]; then

          mkdir -p "$icon_dir"

          install -m 644 \
            "$tmp/$icon_in_appimage" \
            "$icon_file"

          echo "Installed icon: $icon_file"

        else
          # RemNote still works without the icon.
          echo "Warning: icon '$icon_in_appimage' was not found in the AppImage." >&2
          echo "Rofi may show RemNote without an icon." >&2
        fi

        # Install the validated version.
        mv -f "$staged" "$target"

        trap - EXIT
        rm -rf "$tmp"

        echo "Installed RemNote: $target"

        # Refresh the desktop application database.
        [[ -d "$apps_root" ]] &&
          "$UPDATE_DESKTOP_DB" "$apps_root" 2>/dev/null || true
      '';
    };
  };
}
