{ ... }:

{
  home.file = {
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
}
