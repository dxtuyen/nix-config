{ ... }:

{
  home.file = {
    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Restore the saved display mode.
        "$HOME/.local/bin/wlsunset-apply"
        # Wallpaper stays on reload (the awww daemon keeps showing it); sway
        # re-reads the wallust color include -> syncs the palette if missing.
        swaymsg reload
      '';
    };
  };
}
