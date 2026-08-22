{ ... }:

{
  home.file = {
    ".local/bin/pomodoro" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Pomodoro countdown timer
        # Usage: pomodoro {start <minutes>|pause|resume|toggle|reset|status|daemon}

        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/pomodoro-state"
        mkdir -p "$STATE_DIR"

        read_state() {
          if [ -f "$STATE_FILE" ]; then
            . "$STATE_FILE"
          else
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
            TYPE="work"
          fi
        }

        write_state() {
          printf 'DURATION="%s"\nRUNNING="%s"\nEND_TIME="%s"\nREMAINING="%s"\nTYPE="%s"\n' \
            "$DURATION" "$RUNNING" "$END_TIME" "$REMAINING" "$TYPE" > "$STATE_FILE"
        }

        get_remaining() {
          if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
            now=$(date +%s)
            remaining=$((END_TIME - now))
            [ "$remaining" -lt 0 ] && remaining=0
          elif [ -n "$REMAINING" ]; then
            remaining="$REMAINING"
          else
            remaining=0
          fi
          echo "$remaining"
        }

        format_time() {
          local secs=$1
          printf "%02d:%02d" $((secs / 60)) $((secs % 60))
        }

        play_sound() {
          paplay /run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null || true
        }

        daemon_loop() {
          while true; do
            read_state
            if [ "$RUNNING" != "true" ] || [ -z "$END_TIME" ]; then
              exit 0
            fi
            now=$(date +%s)
            remaining=$((END_TIME - now))
            if [ "$remaining" -le 0 ]; then
              finished_duration="$DURATION"
              RUNNING="false"
              END_TIME=""
              REMAINING=""
              DURATION=""
              TYPE="work"
              write_state
              play_sound
              notify-send -a pomodoro -i "chronometer" -t 10000 -u critical \
                "Pomodoro" "Time's up! $finished_duration min session finished 🎉"
              pkill -RTMIN+8 waybar 2>/dev/null || true
              exit 0
            fi
            # Gửi signal mỗi giây để waybar cập nhật đồng hồ mượt mà
            # (daemon đã chạy sẵn nên không tốn thêm tài nguyên đáng kể)
            pkill -RTMIN+8 waybar 2>/dev/null || true
            sleep 1
          done
        }

        ensure_daemon() {
          if pgrep -f "pomodoro daemon" >/dev/null 2>&1; then
            return
          fi
          nohup "$HOME/.local/bin/pomodoro" daemon >/dev/null 2>&1 &
        }

        case "''${1:-status}" in
          start)
            # Usage: pomodoro start [work|break|custom] <minutes>
            # Default type is "work" if not specified
            type_arg="''${2:-}"
            if [[ "$type_arg" =~ ^(work|break|custom)$ ]]; then
              TYPE="$type_arg"
              minutes="''${3:-}"
            else
              TYPE="work"
              minutes="$type_arg"
            fi
            if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
              echo "Usage: pomodoro start [work|break|custom] <minutes> (1-480)" >&2
              exit 1
            fi
            now=$(date +%s)
            DURATION="$minutes"
            RUNNING="true"
            END_TIME=$((now + minutes * 60))
            REMAINING=""
            write_state
            ensure_daemon
            pkill -RTMIN+8 waybar 2>/dev/null || true
            case "$TYPE" in
              break)
                notify-send -a pomodoro -i "chronometer" -t 3000 \
                  "Pomodoro" "Break $minutes min ☕"
                ;;
              custom)
                notify-send -a pomodoro -i "chronometer" -t 3000 \
                  "Pomodoro" "Custom $minutes min ⏱️"
                ;;
              *)
                notify-send -a pomodoro -i "chronometer" -t 3000 \
                  "Pomodoro" "Started $minutes min session 🍅"
                ;;
            esac
            ;;

          pause)
            read_state
            if [ "$RUNNING" = "true" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              write_state
              pkill -RTMIN+8 waybar 2>/dev/null || true
              notify-send -a pomodoro -i "chronometer" -t 2000 "Pomodoro" "Paused ⏸"
            fi
            ;;

          resume)
            read_state
            if [ "$RUNNING" != "true" ] && [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state
              ensure_daemon
              pkill -RTMIN+8 waybar 2>/dev/null || true
              notify-send -a pomodoro -i "chronometer" -t 2000 "Pomodoro" "Resumed ▶"
            fi
            ;;

          toggle)
            read_state
            if [ "$RUNNING" = "true" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              write_state
              pkill -RTMIN+8 waybar 2>/dev/null || true
              notify-send -a pomodoro -i "chronometer" -t 2000 "Pomodoro" "Paused ⏸"
            elif [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state
              ensure_daemon
              pkill -RTMIN+8 waybar 2>/dev/null || true
              notify-send -a pomodoro -i "chronometer" -t 2000 "Pomodoro" "Resumed ▶"
            fi
            ;;

          reset)
            read_state
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
            TYPE="work"
            write_state
            pkill -RTMIN+8 waybar 2>/dev/null || true
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            remaining=$(get_remaining)

            # Trạng thái mặc định (chưa có session / sau reset): icon trung tính ⏱, không cà chua đỏ
            if [ -z "$DURATION" ]; then
              icon="⏱"
              class="idle"
              text="$icon"
              tooltip="Pomodoro - No session"
            else
              case "$TYPE" in
                break)
                  icon="☕"
                  class="break"
                  type_label="Break"
                  ;;
                custom)
                  icon="⏱️"
                  class="custom"
                  type_label="Custom"
                  ;;
                *)
                  icon="🍅"
                  class="running"
                  type_label="Pomodoro"
                  ;;
              esac
              if [ "$RUNNING" = "true" ]; then
                state_icon="▶"
                state_label="Running"
              else
                state_icon="⏹"
                state_label="Stopped"
              fi
              duration_label="$DURATION min"
              text="$icon $(format_time "$remaining") $state_icon"
              tooltip="$type_label $duration_label\\n$state_label | $(format_time "$remaining")"
            fi
            printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
              "$text" "$class" "$tooltip"
            ;;

          *)
            echo "Usage: pomodoro {start <minutes>|pause|resume|toggle|reset|status}" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/pomodoro-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Rofi menu for pomodoro countdown timer
        set -u

        POMODORO="$HOME/.local/bin/pomodoro"
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/pomodoro-state"

        # ═══ CẤU HÌNH THỜI LƯỢNG — chỉ cần sửa ở đây ═══
        # Đổi số phút trong list là menu & lệnh tự cập nhật đồng bộ
        WORK_TIMES="30 60 120"   # phiên Work (phút)
        BREAK_TIMES="5 10 15"    # phiên Break (phút)
        WORK_ICON="🍅"
        BREAK_ICON="☕"

        # Đọc trạng thái hiện tại để hiện Pause/Resume/Reset
        RUNNING="false"
        REMAINING=""
        if [ -f "$STATE_FILE" ]; then
          . "$STATE_FILE"
        fi

        # Sinh danh sách menu từ cấu hình
        MENU=""
        for m in $WORK_TIMES; do
          MENU="$MENU
        $WORK_ICON Start $m min"
        done
        for m in $BREAK_TIMES; do
          MENU="$MENU
        $BREAK_ICON Break $m min"
        done
        MENU="$MENU
        ✏️ Custom time..."

        # Thêm mục Pause/Resume/Reset theo trạng thái
        EXTRA=""
        if [ "$RUNNING" = "true" ]; then
          EXTRA="⏸ Pause
        ↺ Reset"
        elif [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
          EXTRA="▶ Resume
        ↺ Reset"
        fi
        [ -n "$EXTRA" ] && MENU="$EXTRA
        $MENU"

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Pomodoro" \
          -mesg "Type to filter, then press Enter")

        # Xử lý các nút trạng thái
        case "$choice" in
          "⏸ Pause"|"▶ Resume") exec "$POMODORO" toggle ;;
          "↺ Reset") exec "$POMODORO" reset ;;
          "✏️ Custom time...")
            minutes="$(rofi -dmenu -p "Minutes" -mesg "Enter minutes (1-480)" | tr -d '[:space:]')"
            [ -n "$minutes" ] && exec "$POMODORO" start custom "$minutes"
            ;;
        esac

        # Xử lý các lựa chọn start — sinh tự động từ cấu hình
        for m in $WORK_TIMES; do
          [ "$choice" = "$WORK_ICON Start $m min" ] && exec "$POMODORO" start work "$m"
        done
        for m in $BREAK_TIMES; do
          [ "$choice" = "$BREAK_ICON Break $m min" ] && exec "$POMODORO" start break "$m"
        done
      '';
    };
  };
}
