{ ... }:

# Focus: một chế độ duy nhất, không break. Rảnh → nhập 1–480 / preset
# 🍅 30/60/120; có phiên → chỉ ⏸/▶ + ↺. Phiên chạy → dừng swayidle.

{
  home.file = {
    ".local/bin/study" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Usage: study {start|pause|resume|toggle|reset|status|inhibit|...|daemon}

        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/study-state"
        SLEEP_MARKER="$STATE_DIR/study-sleep-paused"
        MANUAL_FLAG="$STATE_DIR/inhibit-manual"
        HISTORY_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro-history.log"
        mkdir -p "$STATE_DIR" "$(dirname "$HISTORY_FILE")"

        read_state() {
          if [ -f "$STATE_FILE" ]; then
            . "$STATE_FILE"
          else
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
          fi
        }

        # Chống idle từ 2 nguồn: phiên chạy (tự động) + bấm tay (thủ công).
        # Có nguồn nào → stop swayidle. Gọi trong write_state nên chỉ chạy lúc
        # chuyển trạng thái, không lặp mỗi giây.
        sync_idle_inhibit() {
          if { [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; } || [ -f "$MANUAL_FLAG" ]; then
            systemctl --user stop swayidle 2>/dev/null || true
          else
            systemctl --user start swayidle 2>/dev/null || true
          fi
        }

        write_state() {
          printf 'DURATION="%s"\nRUNNING="%s"\nEND_TIME="%s"\nREMAINING="%s"\n' \
            "$DURATION" "$RUNNING" "$END_TIME" "$REMAINING" > "$STATE_FILE"
          sync_idle_inhibit
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

        # Giây đã học (kẹp trong [0, DURATION*60]).
        get_elapsed() {
          if [ -z "$DURATION" ]; then
            echo 0
          elif [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
            e=$((DURATION * 60 - (END_TIME - $(date +%s))))
            [ "$e" -gt $((DURATION * 60)) ] && e=$((DURATION * 60))
            [ "$e" -lt 0 ] && e=0
            echo "$e"
          elif [ -n "$REMAINING" ]; then
            e=$((DURATION * 60 - REMAINING))
            [ "$e" -lt 0 ] && e=0
            echo "$e"
          else
            echo $((DURATION * 60))
          fi
        }

        format_time() {
          local secs=$1
          printf "%02d:%02d" $((secs / 60)) $((secs % 60))
        }

        play_sound() {
          paplay /run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga 2>/dev/null || true
        }

        log_history() {
          # $1 = nhãn phiên, $2 = số phút
          printf '%s | %s | %s min\n' "$(date '+%Y-%m-%d %H:%M')" "$1" "$2" >> "$HISTORY_FILE"
        }

        # Ghi lịch sử nếu phiên bị thay thế/reset khi đã học ≥ 1 phút.
        maybe_log_current() {
          elapsed=$(get_elapsed)
          if [ "$elapsed" -ge 60 ]; then
            log_history "$1 (dở dang)" "$((elapsed / 60))"
          fi
        }

        notify_waybar() {
          # Signal 8 = đồng hồ, signal 7 = icon mắt; gọi lúc chuyển trạng thái.
          pkill -RTMIN+8 waybar 2>/dev/null || true
          pkill -RTMIN+7 waybar 2>/dev/null || true
        }

        notify_clock() {
          # Chỉ refresh đồng hồ mỗi giây (icon mắt chỉ đổi lúc chuyển trạng thái).
          pkill -RTMIN+8 waybar 2>/dev/null || true
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
              DURATION=""
              RUNNING="false"
              END_TIME=""
              REMAINING=""
              write_state
              play_sound
              notify-send -a focus -i "chronometer" -t 10000 -u critical \
                "Focus" "Phiên tập trung kết thúc! $finished_duration phút 🍅"
              log_history "focus" "$finished_duration"
              notify_waybar
              exit 0
            fi
            # Mỗi giây chỉ refresh đồng hồ.
            notify_clock
            sleep 1
          done
        }

        # Luôn thay daemon cũ bằng daemon mới (tránh race pause → treo timer).
        ensure_daemon() {
          pkill -f "study daemon" 2>/dev/null || true
          nohup "$HOME/.local/bin/study" daemon >/dev/null 2>&1 &
        }

        # Xóa dấu "ngủ tự pause" khi người dùng thao tác tay.
        clear_sleep_marker() {
          rm -f "$SLEEP_MARKER" 2>/dev/null || true
        }

        case "''${1:-status}" in
          start)
            minutes="''${2:-}"
            # Số nguyên 1–480 (preset đặt ở menu rofi).
            if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
              echo "Usage: study start <1-480>" >&2
              exit 1
            fi
            read_state
            maybe_log_current "focus"
            clear_sleep_marker
            now=$(date +%s)
            DURATION="$minutes"
            RUNNING="true"
            END_TIME=$((now + minutes * 60))
            REMAINING=""
            write_state
            ensure_daemon
            notify_waybar
            notify-send -a focus -i "chronometer" -t 3000 \
              "Focus" "Phiên tập trung $minutes phút bắt đầu 🍅"
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
              # Kill daemon ngay (không chờ tự thoát).
              pkill -f "study daemon" 2>/dev/null || true
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tạm dừng ⏸"
            fi
            ;;

          resume)
            read_state
            clear_sleep_marker
            if [ "$RUNNING" != "true" ] && [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state
              ensure_daemon
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tiếp tục ▶"
            fi
            ;;

          toggle)
            read_state
            clear_sleep_marker
            if [ "$RUNNING" = "true" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              write_state
              # Kill daemon ngay (không chờ tự thoát).
              pkill -f "study daemon" 2>/dev/null || true
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tạm dừng ⏸"
            elif [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state
              ensure_daemon
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tiếp tục ▶"
            fi
            ;;

          reset)
            read_state
            maybe_log_current "focus"
            clear_sleep_marker
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
            write_state
            pkill -f "study daemon" 2>/dev/null || true
            notify_waybar
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            # Daemon chết → finalize phiên hết hạn hoặc hồi sinh daemon.
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              if [ "$((END_TIME - $(date +%s)))" -le 0 ]; then
                finished_duration="$DURATION"
                DURATION=""
                RUNNING="false"
                END_TIME=""
                REMAINING=""
                write_state
                pkill -f "study daemon" 2>/dev/null || true
                play_sound
                notify-send -a focus -i "chronometer" -t 10000 -u critical \
                  "Focus" "Phiên tập trung kết thúc! $finished_duration phút 🍅"
                log_history "focus" "$finished_duration"
                notify_waybar
              elif ! pgrep -f "study daemon" >/dev/null 2>&1; then
                ensure_daemon
                sync_idle_inhibit
              fi
              read_state
            fi
            remaining=$(get_remaining)
            if [ -z "$DURATION" ]; then
              text="⏱"
              class="idle"
              tooltip="🍅 Focus — no session"
            else
              if [ "$RUNNING" = "true" ]; then
                s_icon="▶"
                s_label="Running"
                class="running"
              else
                s_icon="⏸"
                s_label="Paused"
                class="paused"
              fi
              text="🍅 $(format_time "$remaining") $s_icon"
              tooltip="Focus $DURATION min\\n$s_label · $(format_time "$remaining")"
            fi
            printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
              "$text" "$class" "$tooltip"
            ;;

          inhibit)
            # JSON trạng thái chống idle cho Waybar (xanh = tự động, vàng = tay).
            "$0" status >/dev/null 2>&1
            read_state
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
                "$(printf '\xef\x81\xae')" "running" \
                "Focus đang chạy — màn hình không khóa, không ngủ (tự động)\\nBấm = tạm dừng phiên; tắt tay chỉ hiệu lực khi phiên dừng"
            elif [ -f "$MANUAL_FLAG" ]; then
              printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
                "$(printf '\xef\x81\xae')" "manual" \
                "Chống idle BẬT thủ công — màn hình không khóa, không ngủ\\nBấm để tắt"
            else
              printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
                "$(printf '\xef\x81\xb0')" "idle" \
                "Chống idle TẮT — màn hình khóa/tắt/ngủ bình thường\\nBấm để bật (hoặc bắt đầu phiên Focus)"
            fi
            ;;

          inhibit-toggle)
            # Bật/tắt chống idle thủ công. Phiên chạy → tắt tay hiệu lực sau khi phiên dừng.
            read_state
            if [ -f "$MANUAL_FLAG" ]; then
              rm -f "$MANUAL_FLAG"
              toggle_msg="Tắt"
            else
              : > "$MANUAL_FLAG"
              toggle_msg="Bật"
            fi
            sync_idle_inhibit
            notify_waybar
            if [ "$RUNNING" = "true" ] && [ "$toggle_msg" = "Tắt" ]; then
              notify-send -a focus -i "dialog-information" -t 3000 \
                "Chống idle" "Phiên Focus đang chạy — chống idle vẫn giữ đến khi phiên dừng"
            else
              notify-send -a focus -i "dialog-information" -t 2000 \
                "Chống idle" "$toggle_msg chống khóa/tắt màn/ngủ"
            fi
            ;;

          sleep-pause)
            # Máy ngủ: tạm dừng phiên, giữ REMAINING để thời gian ngủ không bị trừ.
            read_state
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              touch "$SLEEP_MARKER"
              write_state
              pkill -f "study daemon" 2>/dev/null || true
              notify_waybar
            fi
            ;;

          sleep-resume)
            # Máy dậy: còn marker → tiếp tục phiên; hết giờ lúc ngủ → finalize.
            read_state
            if [ -f "$SLEEP_MARKER" ]; then
              rm -f "$SLEEP_MARKER" 2>/dev/null || true
              if [ "$RUNNING" != "true" ] && [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
                now=$(date +%s)
                END_TIME=$((now + REMAINING))
                RUNNING="true"
                write_state
                ensure_daemon
                notify-send -a focus -i "chronometer" -t 3000 \
                  "Focus" "Máy vừa thức dậy — phiên tiếp tục ▶"
              elif [ -n "$DURATION" ] && [ "$REMAINING" = "0" ]; then
                finished_duration="$DURATION"
                DURATION=""
                RUNNING="false"
                END_TIME=""
                REMAINING=""
                write_state
                pkill -f "study daemon" 2>/dev/null || true
                play_sound
                notify-send -a focus -i "chronometer" -t 10000 -u critical \
                  "Focus" "Phiên tập trung kết thúc trong lúc máy ngủ! $finished_duration phút 🍅"
                log_history "focus" "$finished_duration"
              fi
            else
              sync_idle_inhibit
            fi
            notify_waybar
            ;;

          *)
            echo "Usage: study {start <1-480>|pause|resume|toggle|reset|status|inhibit|inhibit-toggle|sleep-pause|sleep-resume|daemon}" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/pomodoro-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Rofi một đồng hồ Focus, không break: rảnh → khởi động, có phiên → toggle + reset.
        set -u

        STUDY="$HOME/.local/bin/study"
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"

        format_time() {
          local secs=$1
          printf "%02d:%02d" $((secs / 60)) $((secs % 60))
        }

        # `status` tự finalize/hồi sinh trước khi dựng menu.
        "$STUDY" status >/dev/null

        DURATION=""
        RUNNING="false"
        END_TIME=""
        REMAINING=""
        if [ -f "$STATE_DIR/study-state" ]; then
          # shellcheck disable=SC1090
          . "$STATE_DIR/study-state"
        fi

        if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
          r=$((END_TIME - $(date +%s)))
          [ "$r" -lt 0 ] && r=0
        elif [ -n "$REMAINING" ]; then
          r="$REMAINING"
        else
          r=0
        fi

        # Rảnh → dòng khởi động; có phiên → chỉ toggle + reset.
        if [ -n "$DURATION" ]; then
          if [ "$RUNNING" = "true" ]; then
            ITEMS=("⏸ $(format_time "$r")")
          else
            ITEMS=("▶ $(format_time "$r")")
          fi
          ITEMS+=("↺ Reset")
        else
          ITEMS=("⌨ Minutes (1–480)...")
          ITEMS+=("🍅 30")
          ITEMS+=("🍅 60")
          ITEMS+=("🍅 120")
        fi

        choice=$(printf '%s\n' "''${ITEMS[@]}" | rofi -dmenu -i -p "Focus" \
          -mesg "⌨ minutes 1–480 · 🍅 30/60/120 · ⏸/▶ pause/resume · ↺ reset")

        # Hủy (rỗng) → thoát im lặng; sai định dạng → báo lỗi.
        ask_minutes() {
          local minutes
          minutes=$(rofi -dmenu -p "Focus — minutes (1–480)")
          if [ -z "$minutes" ]; then
            exit 0
          fi
          if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
            notify-send -a focus -i "dialog-error" -t 4000 \
              "Focus" "Invalid minutes: $minutes (need 1–480)"
            exit 1
          fi
          echo "$minutes"
        }

        case "$choice" in
          "⌨ Minutes (1–480)...")
            m=$(ask_minutes) && [ -n "$m" ] && exec "$STUDY" start "$m"
            ;;
          "🍅 30") exec "$STUDY" start 30 ;;
          "🍅 60") exec "$STUDY" start 60 ;;
          "🍅 120") exec "$STUDY" start 120 ;;
          "⏸ "*) exec "$STUDY" toggle ;;
          "▶ "*) exec "$STUDY" toggle ;;
          "↺ Reset") exec "$STUDY" reset ;;
        esac
      '';
    };

    ".local/bin/focus-sleep-watch" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Watcher pause khi ngủ / tiếp tục khi dậy (nghe logind PrepareForSleep).
        # END_TIME wall-clock nên phải giữ REMAINING, không thì timer nhảy cóc.
        set -u
        set -o pipefail

        STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}"

        log() {
          printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
            >> "$STATE_DIR/focus-sleep-watch.log"
        }

        log "watcher khởi động (đang theo dõi PrepareForSleep trên system bus)"

        pending=0
        dbus-monitor --system \
          "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep',sender='org.freedesktop.login1'" 2>/dev/null |
        while IFS= read -r line; do
          case "$line" in
            *"member=PrepareForSleep"*)
              pending=1
              ;;
            *"boolean true"*)
              if [ "${"pending:-0"}" -eq 1 ]; then
                pending=0
                log "máy chuẩn bị ngủ → sleep-pause"
                "$HOME/.local/bin/study" sleep-pause \
                  >> "$STATE_DIR/focus-sleep-watch.log" 2>&1
              fi
              ;;
            *"boolean false"*)
              if [ "${"pending:-0"}" -eq 1 ]; then
                pending=0
                log "máy vừa dậy → sleep-resume"
                "$HOME/.local/bin/study" sleep-resume \
                  >> "$STATE_DIR/focus-sleep-watch.log" 2>&1
              fi
              ;;
          esac
        done
      '';
    };
  };

  # Watcher chạy qua systemd (tự hồi sinh, log journald, dừng theo phiên Sway).
  systemd.user.services.focus-sleep-watch = {
    Unit = {
      Description = "Auto pause/resume Focus timer on system sleep/wake (logind PrepareForSleep)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH cho dbus-monitor + study.
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      ExecStart = "%h/.local/bin/focus-sleep-watch";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
