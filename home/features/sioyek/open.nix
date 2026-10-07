{ pkgs, ... }:

{
  home.file = {
    ".local/bin/sioyek-open" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Reuse an existing Sioyek window for the requested PDF.
        set -u
        JQ="${pkgs.jq}/bin/jq"
        SWAYMSG="${pkgs.sway}/bin/swaymsg"

        if [ $# -ge 1 ]; then
          base="$(basename -- "$1")"
          # Use absolute paths because desktop entries have a limited PATH.
          # Only reuse a window when the filename identifies exactly one.
          # Two PDFs in different directories can share a basename; focusing
          # the first match would silently open the wrong document.
          cid="$($SWAYMSG -t get_tree | $JQ -r --arg b "$base" '
            [.. | objects
             | select(((.app_id? // "") == "sioyek")
                      or (((.window_properties.class? // "") | test("^sioyek$"; "i"))))
             | select((.name // "") | contains($b))
             | .id]
            | if length == 1 then .[0] else empty end')"
          if [ -n "$cid" ]; then
            $SWAYMSG "[con_id=$cid] move container to workspace current"
            $SWAYMSG "[con_id=$cid] focus"
            exit 0
          fi
        else
          # Launching Sioyek from drun has no document argument. Raise an
          # existing window instead of asking Sioyek to reopen the last PDF.
          cid="$($SWAYMSG -t get_tree | $JQ -r '
            [.. | objects
             | select((.app_id? // "") == "sioyek"
                      or ((.window_properties.class? // "") | test("^sioyek$"; "i")))]
             | .[0].id // empty')"
          if [ -n "$cid" ]; then
            $SWAYMSG "[con_id=$cid] move container to workspace current"
            $SWAYMSG "[con_id=$cid] focus"
            exit 0
          fi
        fi

        exec ${pkgs.sioyek}/bin/sioyek "$@"
      '';
    };
  };
}
