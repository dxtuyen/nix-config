{ ... }:

{
  home.file = {
    ".local/bin/toggle-wlsunset" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Vòng lặp: Tự động → Vàng 4000K → Trắng 6500K → Tự động.
        # Query process thực (state file có thể lệch sau restart).
  
        mode="auto"
        pid="$(pgrep -x wlsunset | head -1 2>/dev/null || true)"
        args=""
        if [ -n "$pid" ]; then
          args="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
        fi
  
        case "$args" in
          *"-t 3900"*) mode="warm" ;;
          *"-t 6400"*) mode="cold" ;;
          *) mode="auto" ;;
        esac
  
        pkill -x wlsunset 2>/dev/null || true
  
        case "$mode" in
          auto)
            wlsunset -t 3900 -T 4000 -l 21.0 -L 105.8 &
            label="Vàng 4000K"
            icon="weather-clear-night"
            ;;
          warm)
            wlsunset -t 6400 -T 6500 -l 21.0 -L 105.8 &
            label="Trắng 6500K"
            icon="weather-clear"
            ;;
          cold)
            wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
            label="Tự động"
            icon="preferences-system-time"
            ;;
        esac
  
        notify-send -a wlsunset -i "$icon" -t 2000 "Ánh sáng màn hình" "$label"
      '';
    };
  };
}
