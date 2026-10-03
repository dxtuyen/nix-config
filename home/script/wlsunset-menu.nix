{ ... }:

{
  home.file = {
    ".local/bin/wlsunset-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -u

        mode="unknown"
        pid="$(pgrep -xo wlsunset 2>/dev/null || true)"
        temperature=""
        expect_temperature=false
        if [ -n "$pid" ]; then
          while IFS= read -r -d $'\0' arg; do
            if [ "$expect_temperature" = true ]; then
              temperature="$arg"
              expect_temperature=false
            elif [ "$arg" = "-t" ]; then
              expect_temperature=true
            fi
          done < "/proc/$pid/cmdline" 2>/dev/null || true
        fi

        case "$temperature" in
          3900) mode="warm" ;;
          6400) mode="white" ;;
          4000) mode="natural" ;;
        esac

        label="Not running"
        case "$mode" in
          warm) label="Warm" ;;
          white) label="Cool" ;;
          natural) label="Natural" ;;
        esac

        if [ "''${1:-}" = "status" ]; then
          printf '%s\n' "$label"
          exit 0
        fi

        MENU="○ Warm 4000K
        ○ Cool 6500K
        ○ Natural (automatic)"
        case "$mode" in
          warm) MENU="● Warm 4000K
        ○ Cool 6500K
        ○ Natural (automatic)" ;;
          white) MENU="○ Warm 4000K
        ● Cool 6500K
        ○ Natural (automatic)" ;;
          natural) MENU="○ Warm 4000K
        ○ Cool 6500K
        ● Natural (automatic)" ;;
        esac

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -matching fuzzy -p "Display" \
          -mesg "Current mode: $label · Type to filter")

        case "$choice" in
          *"Warm 4000K") next_mode="warm"; label="Warm"; icon="weather-clear-night" ;;
          *"Cool 6500K") next_mode="white"; label="Cool"; icon="weather-clear" ;;
          *"Natural (automatic)") next_mode="natural"; label="Natural"; icon="preferences-system-time" ;;
          *) exit 0 ;;
        esac

        if [ "$mode" = "$next_mode" ]; then
          exit 0
        fi

        # Đổi mode + LƯU lại (~/.local/state/wlsunset-mode) để còn nguyên sau khi
        # tắt/mở máy — wlsunset-apply giữ args (nguồn duy nhất) + khởi động lại.
        "$HOME/.local/bin/wlsunset-apply" "$next_mode"
        notify-send -a wlsunset -i "$icon" -t 2000 "Display" "$label"
      '';
    };
  };
}
