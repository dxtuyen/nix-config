{ ... }:

{
  home.file = {
    ".local/bin/countdown-menu" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Countdown menu: start, pause/resume, reset, hoặc thêm thời gian.
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
            notify-send -a focus -i "dialog-error" -t 4000 \
              "Countdown" "Invalid minutes: $minutes (need 1–480)"
            exit 1
          fi
          echo "$minutes"
        }

        case "$choice" in
          "⌨ Minutes (1–480)...")
            m=$(ask_minutes) || exit $?
            [ -n "$m" ] || exit 0
            exec "$STUDY" start "$m"
            ;;
          "⏱ 30 min") exec "$STUDY" start 30 ;;
          "⏱ 60 min") exec "$STUDY" start 60 ;;
          "⏱ 120 min") exec "$STUDY" start 120 ;;
          "⏸ "*) exec "$STUDY" toggle ;;
          "▶ "*) exec "$STUDY" toggle ;;
          "↺ Reset") exec "$STUDY" reset ;;
          "＋ Add minutes...")
            m=$(ask_minutes "Countdown — add minutes (1–480)") || exit $?
            [ -n "$m" ] || exit 0
            exec "$STUDY" add "$m"
            ;;
        esac
      '';
    };
  };
}
