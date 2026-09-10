{ ... }:

# Hệ thống focus với 2 CHẾ ĐỘ, chạy SONG SONG, độc lập hoàn toàn:
#   study — phiên học thuần: 3 mốc thời gian cố định 60/90/120 phút, không break
#   burst — duy nhất 1 lựa chọn cố định 10 phút, chạy song song với phiên study
# Mỗi timer có state file + daemon riêng nên chạy đồng thời không ảnh hưởng nhau.
# Lịch sử các phiên ghi vào ~/.local/state/pomodoro-history.log
# Menu rofi ($mod+p): điều khiển chung ở đầu (chỉ hiện khi có phiên), rồi 2 chế độ Burst/Study.

{
  home.file = {
    ".local/bin/study" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Study timer — PHIÊN HỌC THUẦN: mốc thời gian cố định 60/90/120 phút, không break.
        # Usage: study {start <60|90|120>|pause|resume|toggle|reset|status|daemon}

        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/study-state"
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

        write_state() {
          printf 'DURATION="%s"\nRUNNING="%s"\nEND_TIME="%s"\nREMAINING="%s"\n' \
            "$DURATION" "$RUNNING" "$END_TIME" "$REMAINING" > "$STATE_FILE"
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

        # Số giây đã học trong phiên hiện tại (gộp cả thời gian pause)
        get_elapsed() {
          if [ -z "$DURATION" ]; then
            echo 0
          elif [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
            echo $((DURATION * 60 - (END_TIME - $(date +%s))))
          elif [ -n "$REMAINING" ]; then
            echo $((DURATION * 60 - REMAINING))
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

        # Log phiên đang có nếu đã học tối thiểu 1 phút (khi bị thay thế/reset giữa chừng)
        maybe_log_current() {
          elapsed=$(get_elapsed)
          if [ "$elapsed" -ge 60 ]; then
            log_history "$1 (dở dang)" "$((elapsed / 60))"
          fi
        }

        notify_waybar() {
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
              notify-send -a study -i "chronometer" -t 10000 -u critical \
                "Study" "Phiên học kết thúc! $finished_duration min 📚"
              log_history "study" "$finished_duration"
              notify_waybar
              exit 0
            fi
            # Signal mỗi giây để waybar cập nhật đồng hồ mượt mà
            notify_waybar
            sleep 1
          done
        }

        ensure_daemon() {
          if pgrep -f "study daemon" >/dev/null 2>&1; then
            return
          fi
          nohup "$HOME/.local/bin/study" daemon >/dev/null 2>&1 &
        }

        case "''${1:-status}" in
          start)
            minutes="''${2:-}"
            # Chỉ nhận mốc thời gian cố định: 60/90/120 phút (phiên thuần, không break)
            case "$minutes" in
              60|90|120) ;;
              *)
                echo "Usage: study start <60|90|120>" >&2
                exit 1
                ;;
            esac
            read_state
            # Phiên cũ (nếu có) bị thay thế → ghi lịch sử phần đã học
            maybe_log_current "study"
            now=$(date +%s)
            DURATION="$minutes"
            RUNNING="true"
            END_TIME=$((now + minutes * 60))
            REMAINING=""
            write_state
            ensure_daemon
            notify_waybar
            notify-send -a study -i "chronometer" -t 3000 \
              "Study" "Phiên học $minutes min bắt đầu 📚"
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
              notify_waybar
              notify-send -a study -i "chronometer" -t 2000 "Study" "Paused ⏸"
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
              notify_waybar
              notify-send -a study -i "chronometer" -t 2000 "Study" "Resumed ▶"
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
              notify_waybar
              notify-send -a study -i "chronometer" -t 2000 "Study" "Paused ⏸"
            elif [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state
              ensure_daemon
              notify_waybar
              notify-send -a study -i "chronometer" -t 2000 "Study" "Resumed ▶"
            fi
            ;;

          reset)
            read_state
            maybe_log_current "study"
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
            write_state
            notify_waybar
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            remaining=$(get_remaining)
            if [ -z "$DURATION" ]; then
              text="⏱"
              class="idle"
              tooltip="Study — không có phiên"
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
              text="📚 $(format_time "$remaining") $s_icon"
              tooltip="Study $DURATION min\\n$s_label · $(format_time "$remaining")"
            fi
            printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
              "$text" "$class" "$tooltip"
            ;;

          *)
            echo "Usage: study {start <60|90|120>|pause|resume|toggle|reset|status|daemon}" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/burst" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Burst timer — DUY NHẤT 1 lựa chọn cố định 10 PHÚT,
        # chạy SONG SONG với phiên study (độc lập hoàn toàn).
        # Usage: burst {start|pause|resume|toggle|reset|status|daemon}

        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/burst-state"
        HISTORY_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro-history.log"
        mkdir -p "$STATE_DIR" "$(dirname "$HISTORY_FILE")"

        # Duy nhất 1 mốc thời gian: 10 phút cố định
        BURST_MINUTES=10

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

        write_state() {
          printf 'DURATION="%s"\nRUNNING="%s"\nEND_TIME="%s"\nREMAINING="%s"\n' \
            "$DURATION" "$RUNNING" "$END_TIME" "$REMAINING" > "$STATE_FILE"
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

        get_elapsed() {
          if [ -z "$DURATION" ]; then
            echo 0
          elif [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
            echo $((DURATION * 60 - (END_TIME - $(date +%s))))
          elif [ -n "$REMAINING" ]; then
            echo $((DURATION * 60 - REMAINING))
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
          # $1 = nhãn phiên (burst), $2 = số phút
          printf '%s | %s | %s min\n' "$(date '+%Y-%m-%d %H:%M')" "$1" "$2" >> "$HISTORY_FILE"
        }

        maybe_log_current() {
          elapsed=$(get_elapsed)
          if [ "$elapsed" -ge 60 ]; then
            log_history "burst (dở dang)" "$((elapsed / 60))"
          fi
        }

        notify_waybar() {
          pkill -RTMIN+7 waybar 2>/dev/null || true
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
              log_history "burst" "$finished_duration"
              notify_waybar
              notify-send -a burst -i "chronometer" -t 10000 -u critical \
                "Burst xong!" "$finished_duration min 🔥 — Phiên siêu tập trung kết thúc ✅"
              exit 0
            fi
            # Signal mỗi giây để waybar cập nhật đồng hồ mượt mà
            notify_waybar
            sleep 1
          done
        }

        ensure_daemon() {
          if pgrep -f "burst daemon" >/dev/null 2>&1; then
            return
          fi
          nohup "$HOME/.local/bin/burst" daemon >/dev/null 2>&1 &
        }

        case "''${1:-status}" in
          start)
            read_state
            # Phiên cũ (nếu có) bị thay thế → ghi lịch sử phần đã học
            maybe_log_current "burst"
            now=$(date +%s)
            DURATION="$BURST_MINUTES"
            RUNNING="true"
            END_TIME=$((now + BURST_MINUTES * 60))
            REMAINING=""
            write_state
            ensure_daemon
            notify_waybar
            notify-send -a burst -i "chronometer" -t 3000 \
              "Burst" "$BURST_MINUTES min 🔥 — Phiên siêu tập trung bắt đầu (song song với study)"
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
              notify_waybar
              notify-send -a burst -i "chronometer" -t 2000 "Burst" "Paused ⏸"
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
              notify_waybar
              notify-send -a burst -i "chronometer" -t 2000 "Burst" "Resumed ▶"
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
              notify_waybar
              notify-send -a burst -i "chronometer" -t 2000 "Burst" "Paused ⏸"
            elif [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ]; then
              now=$(date +%s)
              END_TIME=$((now + REMAINING))
              RUNNING="true"
              write_state
              ensure_daemon
              notify_waybar
              notify-send -a burst -i "chronometer" -t 2000 "Burst" "Resumed ▶"
            fi
            ;;

          reset)
            read_state
            maybe_log_current "burst"
            DURATION=""
            RUNNING="false"
            END_TIME=""
            REMAINING=""
            write_state
            notify_waybar
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            remaining=$(get_remaining)
            if [ -z "$DURATION" ]; then
              text="🔥"
              class="idle"
              tooltip="Burst 10 min — không có phiên (song song với study)"
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
              text="🔥 $(format_time "$remaining") $s_icon"
              tooltip="Burst $DURATION min\\n$s_label · $(format_time "$remaining")"
            fi
            printf '{"text": "%s", "class": "%s", "tooltip": "%s"}\n' \
              "$text" "$class" "$tooltip"
            ;;

          *)
            echo "Usage: burst {start|pause|resume|toggle|reset|status|daemon}" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/pomodoro-menu" = {
      executable = true;
      text = ''
                #! /usr/bin/env bash
                # Rofi menu: nhóm điều khiển CHUNG ở ĐẦU (Pause/Resume/Reset tác động
                # cả 2 đồng hồ cùng lúc — không cần ghi chú, tự hiểu), chỉ hiện KHI CÓ
                # PHIÊN; rồi 2 chế độ: 🔥 Burst (10 phút) và 📚 Study (60/90/120 phút).
                set -u

                STUDY="$HOME/.local/bin/study"
                BURST="$HOME/.local/bin/burst"
                STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"

                format_time() {
                  local secs=$1
                  printf "%02d:%02d" $((secs / 60)) $((secs % 60))
                }

                # Đọc 1 state file vào biến tiền tố S_ — study/burst dùng cùng tên biến
                # (DURATION, RUNNING, REMAINING...) nên phải tách để không đè nhau.
                get_state() {
                  S_RUN="false"
                  S_REM=""
                  S_DUR=""
                  S_END=""
                  if [ -f "$1" ]; then
                    DURATION=""
                    RUNNING="false"
                    END_TIME=""
                    REMAINING=""
                    # shellcheck disable=SC1090
                    . "$1"
                    S_RUN="$RUNNING"
                    S_REM="$REMAINING"
                    S_DUR="$DURATION"
                    S_END="$END_TIME"
                  fi
                }

                # Giây còn lại của đồng hồ vừa đọc qua get_state (biến S_*)
                s_remaining() {
                  if [ "$S_RUN" = "true" ] && [ -n "$S_END" ]; then
                    r=$((S_END - $(date +%s)))
                    [ "$r" -lt 0 ] && r=0
                  elif [ -n "$S_REM" ]; then
                    r="$S_REM"
                  else
                    r=0
                  fi
                  echo "$r"
                }

                get_state "$STATE_DIR/study-state"
                ST_RUN="$S_RUN"; ST_REM="$S_REM"; ST_DUR="$S_DUR"; ST_LEFT="$(s_remaining)"
                get_state "$STATE_DIR/burst-state"
                BU_RUN="$S_RUN"; BU_REM="$S_REM"; BU_DUR="$S_DUR"; BU_LEFT="$(s_remaining)"

                # ── Nhóm điều khiển CHUNG, luôn ở ĐẦU menu:
                #   ⏸ Pause  — dừng cả 2 đồng hồ đang chạy
                #   ▶ Resume — tiếp tục cả 2 đồng hồ đang tạm dừng
                #   ↺ Reset  — xoá cả 2 phiên
                # Hiện theo trạng thái: Pause khi có gì đang chạy, Resume khi có gì
                # đang pause, Reset khi CÓ PHIÊN. Rảnh hoàn toàn → menu chỉ còn
                # 4 mục khởi động. Không ghi chữ "cả 2" — tự hiểu.
                CTRL_ITEMS=()
                if [ "$ST_RUN" = "true" ] || [ "$BU_RUN" = "true" ]; then
                  CTRL_ITEMS+=("⏸ Pause")
                fi
                if { [ "$ST_RUN" != "true" ] && [ -n "$ST_REM" ] && [ "$ST_REM" -gt 0 ]; } \
                   || { [ "$BU_RUN" != "true" ] && [ -n "$BU_REM" ] && [ "$BU_REM" -gt 0 ]; }; then
                  CTRL_ITEMS+=("▶ Resume")
                fi
                # ↺ Reset chỉ cần khi ĐANG CÓ PHIÊN — rảnh hoàn toàn thì vô nghĩa
                if [ -n "$ST_DUR" ] || [ -n "$BU_DUR" ]; then
                  CTRL_ITEMS+=("↺ Reset")
                fi
                CTRL_TEXT=""
                if [ "''${#CTRL_ITEMS[@]}" -gt 0 ]; then
                  CTRL_TEXT=$(IFS=$'\n'; echo "''${CTRL_ITEMS[*]}")
                fi

                # ── 2 chế độ: đang chạy/pause thì dòng đó chỉ HIỂN THỊ trạng thái
                # (bấm không làm gì), rảnh thì hiện dòng khởi động.
                if [ -n "$BU_DUR" ]; then
                  if [ "$BU_RUN" = "true" ]; then
                    BU_ITEMS="🔥 Burst · còn $(format_time "$BU_LEFT") ▶"
                  else
                    BU_ITEMS="🔥 Burst · tạm dừng $(format_time "$BU_LEFT") ⏸"
                  fi
                else
                  BU_ITEMS="🔥 Burst — siêu tập trung 10 phút"
                fi

                if [ -n "$ST_DUR" ]; then
                  if [ "$ST_RUN" = "true" ]; then
                    ST_ITEMS="📚 Study · còn $(format_time "$ST_LEFT") ▶"
                  else
                    ST_ITEMS="📚 Study · tạm dừng $(format_time "$ST_LEFT") ⏸"
                  fi
                else
                  ST_ITEMS="$(printf '📚 Study — phiên học thuần 60 min\n📚 Study — phiên học thuần 90 min\n📚 Study — phiên học thuần 120 min')"
                fi

                # Menu phẳng, KHÔNG gạch ngang: điều khiển chung ở đầu, rồi 2 chế độ
                if [ -n "$CTRL_TEXT" ]; then
                  MENU="$CTRL_TEXT
        $BU_ITEMS
        $ST_ITEMS"
                else
                  MENU="$BU_ITEMS
        $ST_ITEMS"
                fi

                choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Focus" \
                  -mesg "⏸/▶/↺ dừng/tiếp/xoá cả 2 đồng hồ · 🔥 Burst = 10 phút (song song) · 📚 Study = phiên thuần 60/90/120")

                case "$choice" in
                  "⏸ Pause") "$STUDY" pause; exec "$BURST" pause ;;
                  "▶ Resume") "$STUDY" resume; exec "$BURST" resume ;;
                  "↺ Reset") "$STUDY" reset; exec "$BURST" reset ;;
                  "🔥 Burst — siêu tập trung 10 phút") exec "$BURST" start ;;
                  "📚 Study — phiên học thuần 60 min") exec "$STUDY" start 60 ;;
                  "📚 Study — phiên học thuần 90 min") exec "$STUDY" start 90 ;;
                  "📚 Study — phiên học thuần 120 min") exec "$STUDY" start 120 ;;
                esac
      '';
    };
  };
}
