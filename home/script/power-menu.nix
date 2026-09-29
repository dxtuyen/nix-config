{ ... }:

{
  home.file = {
    ".local/bin/power-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -u

        MENU="⏻ Poweroff
        ↻ Reboot
        ⏾ Suspend
        ⏾ Hibernate
        🔒 Lock"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -matching fuzzy -sort -sorting-method normal -p "Power" \
          -mesg "Select an action, then press Enter")

        case "$choice" in
          "⏻ Poweroff") notify-send -a power -i "system-shutdown" -t 2000 "Power" "Powering off..."; exec systemctl poweroff ;;
          "↻ Reboot") notify-send -a power -i "system-reboot" -t 2000 "Power" "Rebooting..."; exec systemctl reboot ;;
          "⏾ Suspend") notify-send -a power -i "system-suspend" -t 2000 "Power" "Suspending..."; exec systemctl suspend ;;
          "⏾ Hibernate") notify-send -a power -i "system-suspend" -t 2000 "Power" "Hibernating..." ; exec systemctl hibernate ;;
          "🔒 Lock") exec ~/.local/bin/lock-screen ;;
        esac
      '';
    };
  };
}
