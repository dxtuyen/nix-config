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
          🔒 Lock
          ⚡ Power Profile
          ↺ Reload Session
          ⏏ Exit Sway"

          choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Power" \
            -mesg "Select an action, then press Enter")

          case "$choice" in
            "⏻ Poweroff") notify-send -a power -i "system-shutdown" -t 2000 "Power" "Powering off..."; exec systemctl poweroff ;;
            "↻ Reboot") notify-send -a power -i "system-reboot" -t 2000 "Power" "Rebooting..."; exec systemctl reboot ;;
            "⏾ Suspend") notify-send -a power -i "system-suspend" -t 2000 "Power" "Suspending..."; exec systemctl suspend ;;
            "⏾ Hibernate") notify-send -a power -i "system-suspend" -t 2000 "Power" "Hibernating..." ; exec systemctl hibernate ;;
            "🔒 Lock") exec ~/.local/bin/lock-screen ;;
            "⚡ Power Profile") exec ~/.local/bin/power-profile-menu ;;
            "↺ Reload Session") exec ~/.local/bin/refresh-session ;;
            "⏏ Exit Sway") exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit' ;;
          esac
      '';
    };
  };
}
