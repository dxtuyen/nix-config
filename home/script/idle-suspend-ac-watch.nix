{ pkgs, ... }:

{
  home.file = {
    ".local/bin/idle-suspend-ac-watch" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Watcher cho trường hợp idle 900s mà đang cắm sạc: poll pin mỗi 30s.
        # Thoát khi có thao tác / phiên Focus bật / mất sway / rút sạc → suspend.
        while true; do
          out="$(swaymsg -t get_outputs 2>/dev/null)" || exit 0
          [ -n "$out" ] || exit 0
          if printf '%s' "$out" | grep -q '"power": true'; then
            exit 0
          fi
          if pgrep -f "countdown-engine daemon" >/dev/null 2>&1; then
            exit 0
          fi
          for bat in /sys/class/power_supply/BAT*; do
            [ -e "$bat/status" ] || continue
            if [ "$(cat "$bat/status")" = Discharging ]; then
              "$HOME/.local/bin/lock-screen" >/dev/null 2>&1
              exec ${pkgs.systemd}/bin/systemctl suspend
            fi
          done
          sleep 30
        done
      '';
    };
  };
}
