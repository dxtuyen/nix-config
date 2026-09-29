{ ... }:

{
  home.file = {
    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        pkill wlsunset 2>/dev/null || true
        wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
        # Wallpaper giữ nguyên khi reload (awww daemon vẫn hiển thị); sway
        # re-read include màu wallust → đồng bộ palette nếu thiếu.
        swaymsg reload
      '';
    };
  };
}
