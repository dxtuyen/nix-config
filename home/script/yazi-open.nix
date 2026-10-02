{ pkgs, ... }:

{
  home.file = {
    ".local/bin/yazi-open" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Open yazi in a SMALL (popup) foot window — bound to $mod+y for quick file
        # picking / image add-remove. For careful browsing (image/PDF preview) type
        # `yazi` in a terminal instead.
        #
        # Yazi runs INSIDE foot so sway only sees app_id="foot". The dedicated title
        # `yazi-popup` is what makes only this window float (rule in home/config/sway.nix).
        set -u
        TERM_BIN="${pkgs.foot}/bin/foot"
        FOOT_SIZE="--window-size-pixels=1000x700"

        exec "$TERM_BIN" --title=yazi-popup $FOOT_SIZE -e yazi "$@"
      '';
    };
  };
}
