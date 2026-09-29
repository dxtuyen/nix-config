{ pkgs, ... }:

{
  home.file = {
    ".local/bin/study" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Usage: study {start|add|pause|resume|toggle|reset|status|inhibit|...|daemon}

        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/study-state"
        # Keep the lock under persistent state even when STATE_DIR is runtime-only.
        LOCK_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/study-state.lock"
        FLOCK="${pkgs.util-linux}/bin/flock"
        SLEEP_MARKER="$STATE_DIR/study-sleep-paused"
        MANUAL_FLAG="$STATE_DIR/inhibit-manual"
        HISTORY_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro-history.log"
        mkdir -p "$STATE_DIR" "$(dirname "$LOCK_FILE")" "$(dirname "$HISTORY_FILE")"
        exec 9>>"$LOCK_FILE"

        # Serialize state transitions shared by Waybar, the menu and the timer daemon.
        state_lock() {
          "$FLOCK" -x 9 || {
            echo "study: cannot acquire state lock" >&2
            exit 1
          }
        }

        state_unlock() {
          "$FLOCK" -u 9 || {
            echo "study: cannot release state lock" >&2
            exit 1
          }
        }

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
          local tmp
          # Same-directory rename keeps readers from seeing a partially written state.
          tmp=$(mktemp "$STATE_FILE.XXXXXX") || return 1
          if ! printf 'DURATION="%s"\nRUNNING="%s"\nEND_TIME="%s"\nREMAINING="%s"\n' \
            "$DURATION" "$RUNNING" "$END_TIME" "$REMAINING" > "$tmp"; then
            rm -f -- "$tmp"
            return 1
          fi
          if ! mv -f -- "$tmp" "$STATE_FILE"; then
            rm -f -- "$tmp"
            return 1
          fi
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
            # Atomic rename makes this snapshot safe without locking every second.
            read_state
            if [ "$RUNNING" != "true" ] || [ -z "$END_TIME" ]; then
              exit 0
            fi
            now=$(date +%s)
            remaining=$((END_TIME - now))
            if [ "$remaining" -le 0 ]; then
              state_lock
              read_state
              finished_duration=""
              finalize_if_expired || {
                state_unlock
                exit 1
              }
              still_running="$RUNNING"
              still_has_end_time="$END_TIME"
              state_unlock
              if [ -n "$finished_duration" ]; then
                play_sound
                notify-send -a focus -i "chronometer" -t 10000 -u critical \
                  "Focus" "Phiên tập trung kết thúc! $finished_duration phút 🍅"
                log_history "focus" "$finished_duration"
                notify_waybar
                exit 0
              fi
              if [ "$still_running" != "true" ] || [ -z "$still_has_end_time" ]; then
                exit 0
              fi
            fi
            # Mỗi giây chỉ refresh đồng hồ.
            notify_clock
            sleep 1
          done
        }

        # Luôn thay daemon cũ bằng daemon mới (tránh race pause → treo timer).
        ensure_daemon() {
          pkill -f "study daemon" 2>/dev/null || true
          nohup "$HOME/.local/bin/study" daemon 9>&- >/dev/null 2>&1 &
        }

        # Xóa dấu "ngủ tự pause" khi người dùng thao tác tay.
        clear_sleep_marker() {
          rm -f "$SLEEP_MARKER" 2>/dev/null || true
        }

        # Must be called under state_lock; only one caller can finalize a session.
        finalize_if_expired() {
          if [ "$RUNNING" != "true" ] || [ -z "$END_TIME" ]; then
            return 0
          fi
          now=$(date +%s)
          [ "$END_TIME" -gt "$now" ] && return 0

          finished_duration="$DURATION"
          DURATION=""
          RUNNING="false"
          END_TIME=""
          REMAINING=""
          write_state || return 1
          pkill -f "study daemon" 2>/dev/null || true
        }

        case "''${1:-status}" in
          start)
            minutes="''${2:-}"
            # Số nguyên 1–480 (preset đặt ở menu rofi).
            if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
              echo "Usage: study start <1-480>" >&2
              exit 1
            fi
            state_lock
            read_state
            maybe_log_current "focus"
            clear_sleep_marker
            now=$(date +%s)
            DURATION="$minutes"
            RUNNING="true"
            END_TIME=$((now + minutes * 60))
            REMAINING=""
            write_state || exit 1
            ensure_daemon
            state_unlock
            notify_waybar
            notify-send -a focus -i "chronometer" -t 3000 \
              "Focus" "Phiên tập trung $minutes phút bắt đầu 🍅"
            ;;

          add)
            minutes="''${2:-}"
            if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
              echo "Usage: study add <1-480>" >&2
              exit 1
            fi
            # Finalize first if the session elapsed while its menu was open.
            "$0" status >/dev/null
            state_lock
            read_state
            if [ -z "$DURATION" ]; then
              state_unlock
              notify-send -a focus -i "dialog-error" -t 4000 \
                "Focus" "Không có phiên để cộng thời gian."
              exit 1
            fi
            new_duration=$((DURATION + minutes))
            if [ "$new_duration" -gt 480 ]; then
              state_unlock
              notify-send -a focus -i "dialog-error" -t 4000 \
                "Focus" "Tổng thời lượng tối đa là 480 phút (hiện tại $DURATION phút)."
              exit 1
            fi
            remaining=$(get_remaining)
            if [ "$remaining" -le 0 ]; then
              state_unlock
              "$0" status >/dev/null
              exit 1
            fi
            clear_sleep_marker
            DURATION="$new_duration"
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              END_TIME=$((END_TIME + minutes * 60))
            else
              REMAINING=$((remaining + minutes * 60))
            fi
            write_state || exit 1
            if [ "$RUNNING" = "true" ]; then
              ensure_daemon
            fi
            state_unlock
            notify_waybar
            notify-send -a focus -i "chronometer" -t 3000 \
              "Focus" "Đã cộng $minutes phút · tổng phiên $DURATION phút"
            ;;

          pause)
            state_lock
            read_state
            if [ "$RUNNING" = "true" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              write_state || exit 1
              # Kill daemon ngay (không chờ tự thoát).
              pkill -f "study daemon" 2>/dev/null || true
              state_unlock
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tạm dừng ⏸"
            else
              state_unlock
            fi
            ;;

          resume)
            state_lock
            read_state
            clear_sleep_marker
            if [ "$RUNNING" != "true" ] && [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state || exit 1
              ensure_daemon
              state_unlock
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tiếp tục ▶"
            else
              state_unlock
            fi
            ;;

          toggle)
            state_lock
            read_state
            clear_sleep_marker
            if [ "$RUNNING" = "true" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              write_state || exit 1
              # Kill daemon ngay (không chờ tự thoát).
              pkill -f "study daemon" 2>/dev/null || true
              state_unlock
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tạm dừng ⏸"
            elif [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state || exit 1
              ensure_daemon
              state_unlock
              notify_waybar
              notify-send -a focus -i "chronometer" -t 2000 "Focus" "Tiếp tục ▶"
            else
              state_unlock
            fi
            ;;

          reset)
            state_lock
            read_state
            maybe_log_current "focus"
            clear_sleep_marker
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
            write_state || exit 1
            pkill -f "study daemon" 2>/dev/null || true
            state_unlock
            notify_waybar
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            finished_duration=""
            # Lock only on expiry or daemon recovery; routine Waybar polls are lock-free.
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              if [ "$((END_TIME - $(date +%s)))" -le 0 ] || ! pgrep -f "study daemon" >/dev/null 2>&1; then
                state_lock
                read_state
                if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
                  finalize_if_expired || {
                    state_unlock
                    exit 1
                  }
                  if [ -z "$finished_duration" ] && ! pgrep -f "study daemon" >/dev/null 2>&1; then
                    ensure_daemon
                    sync_idle_inhibit
                  fi
                fi
                state_unlock
              fi
            fi
            # Refresh from the latest complete snapshot after any locked transition.
            read_state
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
            if [ -n "$finished_duration" ]; then
              play_sound
              notify-send -a focus -i "chronometer" -t 10000 -u critical \
                "Focus" "Phiên tập trung kết thúc! $finished_duration phút 🍅"
              log_history "focus" "$finished_duration"
              notify_waybar
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
            state_lock
            read_state
            if [ -f "$MANUAL_FLAG" ]; then
              rm -f "$MANUAL_FLAG"
              toggle_msg="Tắt"
            else
              : > "$MANUAL_FLAG"
              toggle_msg="Bật"
            fi
            sync_idle_inhibit
            state_unlock
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
            state_lock
            read_state
            sleep_paused=0
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              now=$(date +%s)
              REMAINING=$((END_TIME - now))
              [ "$REMAINING" -lt 0 ] && REMAINING=0
              RUNNING="false"
              END_TIME=""
              touch "$SLEEP_MARKER"
              write_state || exit 1
              pkill -f "study daemon" 2>/dev/null || true
              sleep_paused=1
            fi
            state_unlock
            if [ "$sleep_paused" -eq 1 ]; then
              notify_waybar
            fi
            ;;

          sleep-resume)
            # Máy dậy: còn marker → tiếp tục phiên; hết giờ lúc ngủ → finalize.
            state_lock
            read_state
            resumed=0
            finished_duration=""
            if [ -f "$SLEEP_MARKER" ]; then
              rm -f "$SLEEP_MARKER" 2>/dev/null || true
              if [ "$RUNNING" != "true" ] && [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
                now=$(date +%s)
                END_TIME=$((now + REMAINING))
                RUNNING="true"
                write_state || exit 1
                ensure_daemon
                resumed=1
              elif [ -n "$DURATION" ] && [ "$REMAINING" = "0" ]; then
                finished_duration="$DURATION"
                DURATION=""
                RUNNING="false"
                END_TIME=""
                REMAINING=""
                write_state || exit 1
                pkill -f "study daemon" 2>/dev/null || true
              fi
            else
              sync_idle_inhibit
            fi
            state_unlock
            if [ "$resumed" -eq 1 ]; then
              notify-send -a focus -i "chronometer" -t 3000 \
                "Focus" "Máy vừa thức dậy — phiên tiếp tục ▶"
            elif [ -n "$finished_duration" ]; then
              play_sound
              notify-send -a focus -i "chronometer" -t 10000 -u critical \
                "Focus" "Phiên tập trung kết thúc trong lúc máy ngủ! $finished_duration phút 🍅"
              log_history "focus" "$finished_duration"
            fi
            notify_waybar
            ;;

          *)
            echo "Usage: study {start <1-480>|add <1-480>|pause|resume|toggle|reset|status|inhibit|inhibit-toggle|sleep-pause|sleep-resume|daemon}" >&2
            exit 1
            ;;
        esac
      '';
    };
  };
}
