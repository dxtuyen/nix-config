{ ... }:

{
  home.file = {
    ".local/bin/options" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -u

        MENU="👁 Idle
        ☀ Display
        📶 Wi-Fi
        🔵 Bluetooth
        ⚡ Power Profile"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -matching fuzzy -sort -sorting-method normal -p "Options" \
          -mesg "Type to filter · Enter to select")

        case "$choice" in
          "👁 Idle") exec ~/.local/bin/pomodoro-engine inhibit-toggle ;;
          "☀ Display"*) exec ~/.local/bin/wlsunset-menu ;;
          "📶 Wi-Fi"*) exec foot --app-id=wifitui -T "Wi-Fi" wifitui ;;
          "🔵 Bluetooth"*) exec foot --app-id=bluetui -T "Bluetooth" bluetui ;;
          "⚡ Power Profile"*) exec ~/.local/bin/power-profile-menu ;;
        esac
      '';
    };
  };
}
