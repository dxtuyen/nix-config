{ pkgs, ... }:

{
  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        trap 'kill "$watcher" 2>/dev/null || true; swaymsg "output * power on"' EXIT
        swayidle -w timeout 10 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' &
        watcher=$!
        swaylock -i ${./../wallpapers/nixos.jpg}
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
        esac
      '';
    };

    ".local/bin/toggle-touchpad" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/touchpad-enabled"
        mkdir -p "$STATE_DIR"

        if [ -f "$STATE_FILE" ]; then
          enabled=$(cat "$STATE_FILE")
        else
          enabled="on"
        fi

        case "$enabled" in
          on)
            swaymsg input type:touchpad events disabled
            new_state="off"
            label="Touchpad đã tắt"
            icon="touchpad-disabled"
            ;;
          off)
            swaymsg input type:touchpad events enabled
            new_state="on"
            label="Touchpad đã bật"
            icon="input-touchpad"
            ;;
        esac

        echo "$new_state" > "$STATE_FILE"
        notify-send -a toggle-touchpad -i "$icon" -t 2000 "Touchpad" "$label"
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
            icon="weather-clear-night"
            ;;
          warm)
            wlsunset -t 6400 -T 6500 &
            new_mode="cold"
            label="Trắng 6500K"
            icon="weather-clear"
            ;;
          cold)
            wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
            new_mode="auto"
            label="Tự động"
            icon="preferences-system-time"
            ;;
        esac

        echo "$new_mode" > "$STATE_FILE"
        notify-send -a wlsunset -i "$icon" -t 2000 "Ánh sáng màn hình" "$label"
      '';
    };

    ".local/bin/cycle-power-profile" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        current="$(powerprofilesctl get)"
        case "$current" in
          power-saver) next="balanced"; icon="battery" ;;
          balanced) next="performance"; icon="power-profile-balanced" ;;
          performance) next="power-saver"; icon="power-profile-performance" ;;
          *) next="balanced"; icon="power-profile-balanced" ;;
        esac
        powerprofilesctl set "$next"
        notify-send -a power-profiles -i "$icon" -t 2000 "Power Profile" "$next"
      '';
    };

    ".local/bin/media-notify" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -eu

        if [ "''${MEDIA_NOTIFY_LOCKED:-}" != 1 ]; then
          exec env MEDIA_NOTIFY_LOCKED=1 ${pkgs.util-linux}/bin/flock \
            "''${XDG_RUNTIME_DIR:?}/media-notify.lock" "$0" "$@"
        fi

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
            *MUTED*) 
              notify_replace volume -a volume -i "audio-volume-muted" -h int:value:0 -t 2000 "Volume" "Muted" 
              ;;
            *) 
              if [ "$volume" -ge 70 ]; then
                icon="audio-volume-high"
              elif [ "$volume" -ge 30 ]; then
                icon="audio-volume-medium"
              elif [ "$volume" -gt 0 ]; then
                icon="audio-volume-low"
              else
                icon="audio-volume-muted"
              fi
              notify_replace volume -a volume -i "$icon" -h "int:value:$volume" -t 2000 "Volume" "''${volume}%" 
              ;;
          esac
        }

        notify_microphone() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
          case "$status" in
            *MUTED*) 
              notify_replace microphone -a volume -i "microphone-sensitivity-muted" -t 2000 "Microphone" "Muted" 
              ;;
            *) 
              notify_replace microphone -a volume -i "audio-input-microphone" -t 2000 "Microphone" "On" 
              ;;
          esac
        }

        notify_brightness() {
          # Lấy % độ sáng dạng số nguyên (bỏ ký tự %)
          bright_raw="$(brightnessctl -m | cut -d, -f4)"
          bright_val="''${bright_raw%%%}"
          notify_replace brightness -a brightness -i "display-brightness" -h "int:value:$bright_val" -t 2000 "Brightness" "''${bright_raw}"
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
            notify_brightness
            ;;
          brightness-down)
            brightnessctl set 10%-
            notify_brightness
            ;;
        esac
      '';
    };

    ".local/bin/save-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Lưu snapshot session (workspace + app) vào $XDG_STATE_HOME/sway-session.json
        set -eu

        STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/sway-session.json"
        mkdir -p "$STATE_DIR"

        # Quét cây cửa sổ: gom app theo workspace, bỏ workspace ẩn __i3_scratch
        # và các node không phải cửa sổ thật (không có app_id/class).
        swaymsg -t get_tree | jq -c '
          [ .nodes[]? | select(.type == "output")
            | .nodes[]? | select(.type == "workspace")
            | select(.name != "__i3_scratch")
            | { name: .name, apps: ([ .. | objects
                | select(has("app_id") or has("window_properties"))
                | (.app_id // .window_properties.class // empty)
              ] | unique) }
          ]' > "$STATE_FILE"

        ws_count="$(jq length "$STATE_FILE")"
        app_count="$(jq '[ .[].apps[] ] | length' "$STATE_FILE")"
        notify-send -a save-session -i "document-save" -t 3000 \
          "Session" "Đã lưu session: $ws_count workspaces, $app_count ứng dụng."
      '';
    };

    ".local/bin/restore-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Khôi phục session: mở lại đúng workspace + app (không khôi phục layout)
        set -u

        STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/sway-session.json"

        # Nếu chưa có session lưu -> thông báo và thoát
        if [ ! -s "$STATE_FILE" ]; then
          notify-send -a restore-session -i "dialog-warning" -t 5000 -u normal \
            "Khôi phục Session" "Chưa có session để khôi phục.\nBấm Mod4+Shift+s để lưu session trước."
          exit 0
        fi

        # Map app_id/class -> lệnh mở lại. "" nghĩa là chưa biết cách mở.
        open_app() {
          case "$1" in
            google-chrome|Google-chrome|chrome) cmd="google-chrome" ;;
            obsidian|Obsidian) cmd="obsidian" ;;
            thunar|Thunar) cmd="thunar" ;;
            calibre|Calibre) cmd="calibre" ;;
            sioyek|Sioyek) cmd="sioyek" ;;
            ticktick|TickTick) cmd="ticktick" ;;
            remnote|RemNote|org.remnote*) cmd="remnote" ;;
            foot|foot-*|org.codeberg.dnkl.foot) cmd="foot" ;;
            code|code-oss|Code) cmd="code" ;;
            *) cmd="" ;;
          esac
        }

        # Đếm số cửa sổ hiện có của một app (để chắc chắn chờ cửa sổ MỚI,
        # không nhầm với cửa sổ đã mở sẵn).
        count_app_windows() {
          local target="$1"
          swaymsg -t get_tree 2>/dev/null | jq --arg t "$target" '
            [ .. | objects
              | select(has("app_id") or has("window_properties"))
              | (.app_id // .window_properties.class // "")
              | select(. == $t)
            ] | length'
        }

        # Chờ sway sẵn sàng (tối đa ~6s)
        for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
          swaymsg -t get_workspaces >/dev/null 2>&1 && break
          sleep 0.3
        done

        skipped=""

        mapfile -t workspaces < <(jq -c '.[]' "$STATE_FILE")
        for ws in "''${workspaces[@]}"; do
          name="$(jq -r '.name' <<< "$ws")"
          # Focus workspace này và GIỮ NGUYÊN trong suốt vòng lặp app
          # để cửa sổ mới mở ra luôn rơi vào đúng workspace.
          swaymsg "workspace number $name" >/dev/null 2>&1 || true
          for app in $(jq -r '.apps[]' <<< "$ws"); do
            open_app "$app"
            if [ -z "$cmd" ]; then
              skipped="$skipped $app"
              continue
            fi
            before="$(count_app_windows "$app")"
            swaymsg "exec $cmd" >/dev/null 2>&1 || true
            # Chờ cửa sổ mới xuất hiện (tối đa ~30s) trước khi mở app kế tiếp
            # hoặc chuyển workspace — nhờ đó app luôn mở đúng workspace.
            i=0
            while [ "$i" -lt 60 ]; do
              after="$(count_app_windows "$app")"
              [ "''${after:-0}" -gt "''${before:-0}" ] && break
              sleep 0.5
              i=$((i + 1))
            done
          done
        done

        if [ -n "$skipped" ]; then
          notify-send -a restore-session -i "dialog-information" -t 5000 \
            "Khôi phục Session" "Đã khôi phục.\nBỏ qua (chưa có lệnh):$skipped"
        else
          notify-send -a restore-session -i "view-refresh" -t 4000 \
            "Khôi phục Session" "Đã khôi phục session."
        fi
      '';
    };

    ".local/bin/poweroff-with-save" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Lưu session rồi tắt máy
        "$HOME/.local/bin/save-session"
        systemctl poweroff
      '';
    };

    ".local/bin/poweroff-without-save" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Xóa session lưu rồi tắt máy (tắt thường, không giữ lại session)
        STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}"
        rm -f "$STATE_DIR/sway-session.json"
        systemctl poweroff
      '';
    };

  };

  systemd.user.services.cycle-wallpaper = {
    Unit = {
      Description = "Cycle wallpaper based on time of day";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/cycle-wallpaper";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.timers.cycle-wallpaper = {
    Unit = {
      Description = "Run cycle-wallpaper at 6:00 and 18:00";
    };
    Timer = {
      OnCalendar = [
        "*-*-* 06:00:00"
        "*-*-* 18:00:00"
      ];
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
