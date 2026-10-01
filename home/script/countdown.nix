{ ... }:

{
  home.file = {
    ".local/bin/countdown" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Countdown menu: start, pause/resume, reset, hoặc thêm thời gian.
        set -u

        ENGINE="$HOME/.local/bin/countdown-engine"
        # Tương thích lúc switch: engine mới đọc countdown-state, menu này đọc
        # được cả file cũ (pomodoro-state, study-state). Fallback binary cũ cho
        # máy chưa switch xong (pomodoro-engine, study vẫn còn trong ~/.local/bin).
        for candidate in "$HOME/.local/bin/pomodoro-engine" "$HOME/.local/bin/study"; do
          if [ ! -x "$ENGINE" ] && [ -x "$candidate" ]; then
            ENGINE="$candidate"
          fi
        done
        STATE_DIR="''${XDG_RUNTIME_DIR:-$HOME/.local/state}"

        format_time() {
          local secs=$1
          printf "%02d:%02d" $((secs / 60)) $((secs % 60))
        }

        # `status` tự finalize/hồi sinh trước khi dựng menu.
        "$ENGINE" status >/dev/null

        DURATION=""
        RUNNING="false"
        END_TIME=""
        REMAINING=""
        # Ưu tiên state file mới; chỉ fallback sang tên cũ khi file mới chưa
        # có. (Bẫy cũ: `[ -f "$MENU_STATE" ] || ... || continue` đúng là KHÔNG
        # continue → vẫn ghi đè MENU_STATE bằng tên legacy → menu không thấy
        # phiên đang chạy và luôn hiện màn hình khởi động.)
        MENU_STATE="$STATE_DIR/countdown-state"
        if [ ! -f "$MENU_STATE" ]; then
          for legacy in "$STATE_DIR/pomodoro-state" "$STATE_DIR/study-state"; do
            if [ -f "$legacy" ]; then
              MENU_STATE="$legacy"
              break
            fi
          done
        fi
        if [ -f "$MENU_STATE" ]; then
          # shellcheck disable=SC1090
          . "$MENU_STATE"
        fi

        if [ "$RUNNING" = "true" ] && [ -n "$END_TIME" ]; then
          r=$((END_TIME - $(date +%s)))
          [ "$r" -lt 0 ] && r=0
        elif [ -n "$REMAINING" ]; then
          r="$REMAINING"
        else
          r=0
        fi

        # Rảnh → dòng khởi động; có phiên → toggle, reset hoặc cộng phút.
        if [ -n "$DURATION" ]; then
          if [ "$RUNNING" = "true" ]; then
            ITEMS=("⏸ $(format_time "$r")")
          else
            ITEMS=("▶ $(format_time "$r")")
          fi
          ITEMS+=("↺ Reset")
          ITEMS+=("＋ Add minutes...")
        else
          ITEMS=("⌨ Minutes (1–480)...")
          ITEMS+=("⏱ 30 min")
          ITEMS+=("⏱ 60 min")
          ITEMS+=("⏱ 120 min")
        fi

        choice=$(printf '%s\n' "''${ITEMS[@]}" | rofi -dmenu -i -p "Countdown" \
          -mesg "⌨ start 1–480 · ⏱ 30/60/120 min · ⏸/▶ pause/resume · ↺ reset · ＋ add minutes")

        # Hủy (rỗng) → thoát im lặng; sai định dạng → báo lỗi.
        ask_minutes() {
          local prompt="''${1:-Countdown — minutes (1–480)}"
          local minutes
          minutes=$(rofi -dmenu -p "$prompt")
          if [ -z "$minutes" ]; then
            exit 0
          fi
          if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]] || [ "$minutes" -lt 1 ] || [ "$minutes" -gt 480 ]; then
            notify-send -a countdown -i "dialog-error" -t 4000 \
              "Countdown" "Invalid minutes: $minutes (need 1–480)"
            exit 1
          fi
          echo "$minutes"
        }

        case "$choice" in
          "⌨ Minutes (1–480)...")
            m=$(ask_minutes) || exit $?
            [ -n "$m" ] || exit 0
            exec "$ENGINE" start "$m"
            ;;
          "⏱ 30 min") exec "$ENGINE" start 30 ;;
          "⏱ 60 min") exec "$ENGINE" start 60 ;;
          "⏱ 120 min") exec "$ENGINE" start 120 ;;
          "⏸ "*) exec "$ENGINE" toggle ;;
          "▶ "*) exec "$ENGINE" toggle ;;
          "↺ Reset") exec "$ENGINE" reset ;;
          "＋ Add minutes...")
            m=$(ask_minutes "Countdown — add minutes (1–480)") || exit $?
            [ -n "$m" ] || exit 0
            exec "$ENGINE" add "$m"
            ;;
        esac
      '';
    };
  };
}
