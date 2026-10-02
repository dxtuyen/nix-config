{ pkgs, ... }:

{
  home.file = {
    ".local/bin/idle-suspend" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Only suspend on battery. Plugged in -> stay awake (screen still off & locked).
        # Focus session running -> no suspend (END_TIME is wall-clock).
        if pgrep -f "(countdown|pomodoro)-engine daemon" >/dev/null 2>&1; then
          exit 0
        fi
        for bat in /sys/class/power_supply/BAT*; do
          [ -e "$bat/status" ] || continue
          if [ "$(cat "$bat/status")" = Discharging ]; then
            exec ${pkgs.systemd}/bin/systemctl suspend
          fi
        done
        # Planted while plugged in: if unplugged while still idle -> lock + suspend
        # (swayidle only fires the 900s timeout once per cycle).
        if ! pgrep -f idle-suspend-ac-watch >/dev/null 2>&1; then
          ${pkgs.bash}/bin/bash "$HOME/.local/bin/idle-suspend-ac-watch" >/dev/null 2>&1 &
        fi
      '';
    };
  };
}
