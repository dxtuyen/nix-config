{ ... }:

# Hệ thống focus với 2 CHẾ ĐỘ, chạy SONG SONG, độc lập hoàn toàn:
#   study — phiên học thuần: preset 60/90/120 hoặc tự nhập 1–480 phút, không break
#   burst — mặc định 10 phút (tự nhập được 1–480), chạy song song với phiên study
# Mỗi timer có state file + daemon riêng nên chạy đồng thời không ảnh hưởng nhau.
# Daemon chết giữa chừng → `status` tự hồi sinh (spawn lại) hoặc tự finalize phiên
# đã hết hạn (chuông/thông báo/lịch sử) — không bao giờ kẹt "còn 00:00" vĩnh viễn.
# Lịch sử các phiên ghi vào ~/.local/state/pomodoro-history.log
# Menu rofi ($mod+p): KHÔNG có điều khiển chung — mỗi dòng = 1 hành động cho chính
# đồng hồ đó (⏸/▶ pause-resume, ↺ Reset riêng); rảnh thì hiện các dòng khởi động.

{
  home.file = {
    ".local/bin/study" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Study timer — PHIÊN HỌC THUẦN: preset 60/90/120 hoặc tự nhập 1–480 phút, không break.
        # Usage: study {start <1-480>|pause|resume|toggle|reset|status|daemon}

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

        # Số giây đã học trong phiên hiện tại (gộp cả thời gian pause);
        # luôn kẹp trong [0, DURATION*60] — END_TIME đã qua thì không cộng thừa
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

        # Luôn THAY daemon cũ bằng daemon mới (pkill rồi spawn). Nếu chỉ pgrep-check
        # thì daemon cũ vừa nhận lệnh pause có thể chưa kịp chết → tưởng còn sống →
        # không spawn → sau resume không còn daemon nào → timer treo, không chuông.
        ensure_daemon() {
          pkill -f "study daemon" 2>/dev/null || true
          nohup "$HOME/.local/bin/study" daemon >/dev/null 2>&1 &
        }

        case "''${1:-status}" in
          start)
            minutes="''${2:-}"
            # Nhận mọi số nguyên 1–480 phút (preset 60/90/120 đặt ở menu rofi)
            if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
              echo "Usage: study start <1-480>" >&2
              exit 1
            fi
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
              # Kill daemon ngay — không chờ nó tự thoát (nguồn gốc race cũ)
              pkill -f "study daemon" 2>/dev/null || true
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
              # Kill daemon ngay — không chờ nó tự thoát (nguồn gốc race cũ)
              pkill -f "study daemon" 2>/dev/null || true
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
            pkill -f "study daemon" 2>/dev/null || true
            notify_waybar
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            # Tự phục hồi khi daemon đã chết giữa chừng:
            #   - phiên đã hết hạn → finalize tại chỗ (chuông, thông báo, lịch sử)
            #   - phiên còn thời gian → hồi sinh daemon
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
                notify-send -a study -i "chronometer" -t 10000 -u critical \
                  "Study" "Phiên học kết thúc! $finished_duration min 📚"
                log_history "study" "$finished_duration"
                notify_waybar
              elif ! pgrep -f "study daemon" >/dev/null 2>&1; then
                ensure_daemon
              fi
              read_state
            fi
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
            echo "Usage: study {start <1-480>|pause|resume|toggle|reset|status|daemon}" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/burst" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Burst timer — mặc định 10 PHÚT (tự nhập được: burst start <1-480>),
        # chạy SONG SONG với phiên study (độc lập hoàn toàn).
        # Usage: burst {start [1-480]|pause|resume|toggle|reset|status|daemon}

        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"
        STATE_FILE="$STATE_DIR/burst-state"
        HISTORY_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/pomodoro-history.log"
        mkdir -p "$STATE_DIR" "$(dirname "$HISTORY_FILE")"

        # Mốc mặc định: 10 phút (burst start <phút> để tự nhập 1–480)
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

        # Số giây đã chạy (gộp cả thời gian pause); luôn kẹp trong [0, DURATION*60]
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

        # Luôn THAY daemon cũ bằng daemon mới (pkill rồi spawn). Nếu chỉ pgrep-check
        # thì daemon cũ vừa nhận lệnh pause có thể chưa kịp chết → tưởng còn sống →
        # không spawn → sau resume không còn daemon nào → timer treo, không chuông.
        ensure_daemon() {
          pkill -f "burst daemon" 2>/dev/null || true
          nohup "$HOME/.local/bin/burst" daemon >/dev/null 2>&1 &
        }

        case "''${1:-status}" in
          start)
            # Mặc định 10 phút; `burst start <phút>` để tự nhập (1–480)
            minutes="''${2:-$BURST_MINUTES}"
            if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
              echo "Usage: burst start [1-480]" >&2
              exit 1
            fi
            read_state
            # Phiên cũ (nếu có) bị thay thế → ghi lịch sử phần đã học
            maybe_log_current "burst"
            now=$(date +%s)
            DURATION="$minutes"
            RUNNING="true"
            END_TIME=$((now + minutes * 60))
            REMAINING=""
            write_state
            ensure_daemon
            notify_waybar
            notify-send -a burst -i "chronometer" -t 3000 \
              "Burst" "$minutes min 🔥 — Phiên siêu tập trung bắt đầu (song song với study)"
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
              # Kill daemon ngay — không chờ nó tự thoát (nguồn gốc race cũ)
              pkill -f "burst daemon" 2>/dev/null || true
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
              # Kill daemon ngay — không chờ nó tự thoát (nguồn gốc race cũ)
              pkill -f "burst daemon" 2>/dev/null || true
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
            pkill -f "burst daemon" 2>/dev/null || true
            notify_waybar
            ;;

          daemon)
            daemon_loop
            ;;

          status)
            read_state
            # Tự phục hồi khi daemon đã chết giữa chừng:
            #   - phiên đã hết hạn → finalize tại chỗ (chuông, thông báo, lịch sử)
            #   - phiên còn thời gian → hồi sinh daemon
            if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
              if [ "$((END_TIME - $(date +%s)))" -le 0 ]; then
                finished_duration="$DURATION"
                DURATION=""
                RUNNING="false"
                END_TIME=""
                REMAINING=""
                write_state
                pkill -f "burst daemon" 2>/dev/null || true
                play_sound
                log_history "burst" "$finished_duration"
                notify_waybar
                notify-send -a burst -i "chronometer" -t 10000 -u critical \
                  "Burst xong!" "$finished_duration min 🔥 — Phiên siêu tập trung kết thúc ✅"
              elif ! pgrep -f "burst daemon" >/dev/null 2>&1; then
                ensure_daemon
              fi
              read_state
            fi
            remaining=$(get_remaining)
            if [ -z "$DURATION" ]; then
              text="🔥"
              class="idle"
              tooltip="Burst — mặc định 10 min, tự nhập được (song song với study)"
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
            echo "Usage: burst {start [1-480]|pause|resume|toggle|reset|status|daemon}" >&2
            exit 1
            ;;
        esac
      '';
    };

    ".local/bin/pomodoro-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Rofi menu: KHÔNG có điều khiển chung — mỗi dòng = 1 hành động cho
        # chính đồng hồ đó: rảnh → dòng khởi động (preset + tự nhập 1–480
        # phút); đang chạy → ⏸ bấm để pause; tạm dừng → ▶ bấm để resume;
        # ↺ Reset riêng cho từng đồng hồ (chỉ hiện khi đồng hồ đó có phiên).
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

        # Tự phục hồi trước khi dựng menu: `status` sẽ finalize phiên đã
        # hết hạn (chuông/thông báo/lịch sử) và hồi sinh daemon đã chết.
        "$STUDY" status >/dev/null
        "$BURST" status >/dev/null

        get_state "$STATE_DIR/study-state"
        ST_RUN="$S_RUN"; ST_REM="$S_REM"; ST_DUR="$S_DUR"; ST_LEFT="$(s_remaining)"
        get_state "$STATE_DIR/burst-state"
        BU_RUN="$S_RUN"; BU_REM="$S_REM"; BU_DUR="$S_DUR"; BU_LEFT="$(s_remaining)"

        # ── Mỗi dòng = 1 hành động trực tiếp cho chính đồng hồ đó
        # (không có dòng "dead" — mọi dòng hiện ra đều bấm được):
        #   rảnh        → dòng khởi động (preset + tự nhập 1–480 phút)
        #   đang chạy   → ⏸ bấm để pause
        #   tạm dừng    → ▶ bấm để resume
        #   có phiên    → ↺ Reset riêng của đồng hồ đó
        BU_ITEMS=()
        if [ -n "$BU_DUR" ]; then
          if [ "$BU_RUN" = "true" ]; then
            BU_ITEMS+=("⏸ Burst · còn $(format_time "$BU_LEFT")")
          else
            BU_ITEMS+=("▶ Burst · tạm dừng $(format_time "$BU_LEFT")")
          fi
          BU_ITEMS+=("↺ Reset Burst")
        else
          BU_ITEMS+=("🔥 Burst — mặc định 10 phút")
          BU_ITEMS+=("🔥 Burst — tự nhập số phút (1–480)...")
        fi

        ST_ITEMS=()
        if [ -n "$ST_DUR" ]; then
          if [ "$ST_RUN" = "true" ]; then
            ST_ITEMS+=("⏸ Study · còn $(format_time "$ST_LEFT")")
          else
            ST_ITEMS+=("▶ Study · tạm dừng $(format_time "$ST_LEFT")")
          fi
          ST_ITEMS+=("↺ Reset Study")
        else
          ST_ITEMS+=("📚 Study — phiên học thuần 60 min")
          ST_ITEMS+=("📚 Study — phiên học thuần 90 min")
          ST_ITEMS+=("📚 Study — phiên học thuần 120 min")
          ST_ITEMS+=("📚 Study — tự nhập số phút (1–480)...")
        fi

        MENU=$(printf '%s\n' "''${BU_ITEMS[@]}" "''${ST_ITEMS[@]}")

        choice=$(printf '%s\n' "$MENU" | rofi -dmenu -i -p "Focus" \
          -mesg "Mỗi dòng là hành động cho chính đồng hồ đó · ⏸/▶ pause/resume · ↺ Reset riêng từng đồng hồ · tự nhập 1–480 phút")

        # Hỏi số phút tự nhập qua rofi; hủy (rỗng) → thoát im lặng,
        # sai (không phải số nguyên 1–480) → thông báo lỗi rồi thoát.
        ask_minutes() {
          local minutes
          minutes=$(rofi -dmenu -p "$1 — số phút (1–480)")
          if [ -z "$minutes" ]; then
            exit 0
          fi
          if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
            notify-send -a "$2" -i "dialog-error" -t 4000 \
              "$1" "Số phút không hợp lệ: $minutes (cần 1–480)"
            exit 1
          fi
          echo "$minutes"
        }

        case "$choice" in
          "⏸ Burst"*) exec "$BURST" toggle ;;
          "▶ Burst"*) exec "$BURST" toggle ;;
          "↺ Reset Burst") exec "$BURST" reset ;;
          "🔥 Burst — mặc định 10 phút") exec "$BURST" start ;;
          "🔥 Burst — tự nhập số phút (1–480)...")
            m=$(ask_minutes "Burst" burst) && [ -n "$m" ] && exec "$BURST" start "$m"
            ;;
          "⏸ Study"*) exec "$STUDY" toggle ;;
          "▶ Study"*) exec "$STUDY" toggle ;;
          "↺ Reset Study") exec "$STUDY" reset ;;
          "📚 Study — phiên học thuần 60 min") exec "$STUDY" start 60 ;;
          "📚 Study — phiên học thuần 90 min") exec "$STUDY" start 90 ;;
          "📚 Study — phiên học thuần 120 min") exec "$STUDY" start 120 ;;
          "📚 Study — tự nhập số phút (1–480)...")
            m=$(ask_minutes "Study" study) && [ -n "$m" ] && exec "$STUDY" start "$m"
            ;;
        esac
      '';
    };
  };
}
