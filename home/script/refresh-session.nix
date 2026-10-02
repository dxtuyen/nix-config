{ ... }:

{
  home.file = {
    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        pkill wlsunset 2>/dev/null || true
        wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
        # Wallpaper stays on reload (the awww daemon keeps showing it); sway
        # re-reads the wallust color include -> syncs the palette if missing.
        swaymsg reload
      '';
    };
  };
}
