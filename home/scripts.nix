{ pkgs, ... }:

{
  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        swayidle -w timeout 10 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' &
        watcher=$!
        swaylock -f -i ${./../wallpapers/nixos.jpg}
        kill "$watcher" 2>/dev/null || true
        swaymsg "output * power on"
      '';
    };
    ".local/bin/cycle-wallpaper" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Đổi wallpaper theo giờ: 6:00-17:59 sáng, 18:00-5:59 tối
        hour="$(date +%H)"
        if [ "$hour" -ge 6 ] && [ "$hour" -lt 18 ]; then
          swaymsg "output * bg ${./../wallpapers/tokyonight-bright.jpg} fill"
        else
          swaymsg "output * bg ${./../wallpapers/tokyonight-night.png} fill"
        fi
      '';
    };
    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        pkill wlsunset 2>/dev/null || true
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        echo "auto" > "$STATE_DIR/wlsunset-mode" 2>/dev/null || true
        wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
        swaymsg reload
        # Đặt lại ảnh nền đúng theo giờ sau khi reload
        ~/.local/bin/cycle-wallpaper
      '';
    };
    ".local/bin/quick-lang" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        mode="''${1:-vi-en}"
        text="$(wl-paste -p 2>/dev/null || wl-paste 2>/dev/null || true)"
        [ -n "''${text//[[:space:]]/}" ] || { notify-send -a quick-lang -t 7000 "Quick Lang" "Không có văn bản nào được chọn hoặc copy."; exit 1; }
        case "$mode" in
          vi-en) result="$(trans -b vi:en "$text")"; printf %s "$result" | wl-copy; notify-send -a quick-lang -t 7000 "VI → EN" "$result" ;;
          en-vi) result="$(trans -b en:vi "$text")"; printf %s "$result" | wl-copy; notify-send -a quick-lang -t 7000 "EN → VI" "$result" ;;
          polish) printf '%s' "Rewrite and improve this English text. Return only the improved version:\n\n$text" | wl-copy; notify-send -a quick-lang -t 7000 "English Polish" "Prompt đã được copy." ;;
        esac
      '';
    };
    ".local/bin/toggle-wlsunset" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/wlsunset-mode"
        mkdir -p "$STATE_DIR"

        if [ -f "$STATE_FILE" ]; then
          mode=$(cat "$STATE_FILE")
        else
          mode="auto"
          echo "$mode" > "$STATE_FILE"
        fi

        pkill -x wlsunset 2>/dev/null

        case "$mode" in
          auto)
            wlsunset -t 3900 -T 4000 &
            new_mode="warm"
            label="Vàng 4000K"
            ;;
          warm)
            wlsunset -t 6400 -T 6500 &
            new_mode="cold"
            label="Trắng 6500K"
            ;;
          cold)
            wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
            new_mode="auto"
            label="Tự động"
            ;;
        esac

        echo "$new_mode" > "$STATE_FILE"
        notify-send -a wlsunset -t 2000 "$label"
      '';
    };
    ".local/bin/cycle-power-profile" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        current="$(powerprofilesctl get)"
        case "$current" in
          power-saver) next="balanced" ;;
          balanced) next="performance" ;;
          performance) next="power-saver" ;;
          *) next="balanced" ;;
        esac
        powerprofilesctl set "$next"
        notify-send -a power-profiles -t 2000 "Power Profile" "$next"
      '';
    };
    ".local/bin/media-notify" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -eu

        # Sway runs one process per key press. Serialize them so every request
        # updates the same notification instead of racing to create a new one.
        if [ "''${MEDIA_NOTIFY_LOCKED:-}" != 1 ]; then
          exec env MEDIA_NOTIFY_LOCKED=1 ${pkgs.util-linux}/bin/flock \
            "''${XDG_RUNTIME_DIR:?}/media-notify.lock" "$0" "$@"
        fi

        # A replacement ID must be one assigned by mako, rather than a fixed
        # arbitrary number. Keep the most recently assigned ID for each kind
        # of notification so rapid key presses update the visible popup.
        notify_replace() {
          name="$1"
          shift
          id_file="''${XDG_RUNTIME_DIR:?}/media-notify-''${name}.id"
          replace_id=""

          if [ -r "$id_file" ]; then
            read -r replace_id < "$id_file" || true
            case "$replace_id" in
              *[!0-9]*|"") replace_id="" ;;
            esac
          fi

          if [ -n "$replace_id" ]; then
            notification_id="$(notify-send -p -r "$replace_id" "$@")"
          else
            notification_id="$(notify-send -p "$@")"
          fi

          case "$notification_id" in
            *[!0-9]*|"") ;;
            *) printf '%s\n' "$notification_id" > "$id_file" ;;
          esac
        }

        notify_volume() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
          volume="$(printf '%s\n' "$status" | awk '{ printf "%d", ($2 * 100) + 0.5 }')"
          case "$status" in
            *MUTED*) notify_replace volume -a volume -t 2000 "Volume" "Muted" ;;
            *) notify_replace volume -a volume -t 2000 "Volume" "''${volume}%" ;;
          esac
        }

        notify_microphone() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
          case "$status" in
            *MUTED*) notify_replace microphone -a volume -t 2000 "Microphone" "Muted" ;;
            *) notify_replace microphone -a volume -t 2000 "Microphone" "On" ;;
          esac
        }

        case "''${1:?missing action}" in
          volume-up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; notify_volume ;;
          volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; notify_volume ;;
          volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; notify_volume ;;
          mic-mute)
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            notify_microphone
            ;;
          brightness-up)
            brightnessctl set +10%
            notify_replace brightness -a brightness -t 2000 "Brightness" "$(brightnessctl -m | cut -d, -f4)"
            ;;
          brightness-down)
            brightnessctl set 10%-
            notify_replace brightness -a brightness -t 2000 "Brightness" "$(brightnessctl -m | cut -d, -f4)"
            ;;
        esac
      '';
    };
  };

  # Systemd timer: chạy cycle-wallpaper đúng 6:00 và 18:00 mỗi ngày
  # để đổi wallpaper sáng/tối. Không cần process chạy nền.
  systemd.user.services.cycle-wallpaper = {
    Unit.Description = "Cycle wallpaper based on time of day";
    Install.WantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/cycle-wallpaper";
    };
  };

  systemd.user.timers.cycle-wallpaper = {
    Unit.Description = "Run cycle-wallpaper at 6:00 and 18:00";
    Install.WantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 6,18:00:00";
    };
  };
}
