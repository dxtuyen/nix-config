{ pkgs, ... }:

{
  home.file = {
    ".local/bin/idle-suspend" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Chỉ ngủ khi dùng pin. Cắm sạc → thức tiếp (màn vẫn tắt & khóa).
        # Phiên Focus chạy → không suspend (END_TIME wall-clock).
        if pgrep -f "pomodoro-engine daemon" >/dev/null 2>&1; then
          exit 0
        fi
        for bat in /sys/class/power_supply/BAT*; do
          [ -e "$bat/status" ] || continue
          if [ "$(cat "$bat/status")" = Discharging ]; then
            exec ${pkgs.systemd}/bin/systemctl suspend
          fi
        done
        # Cắm sạc → trồng watcher: rút sạc khi vẫn idle → khóa + suspend
        # (swayidle chỉ chạy timeout 900 một lần mỗi chu kỳ).
        if ! pgrep -f idle-suspend-ac-watch >/dev/null 2>&1; then
          ${pkgs.bash}/bin/bash "$HOME/.local/bin/idle-suspend-ac-watch" >/dev/null 2>&1 &
        fi
      '';
    };
  };
}
