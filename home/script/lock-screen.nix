{ pkgs, ... }:

{
  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Locking -> pause the session immediately (no-op without a session/already paused);
        # unlocking does NOT auto-resume — press ▶ to continue. Runs BEFORE the guard so a
        # stacking lock (swaylock already running) still does not miss the pause.
        "$HOME/.local/bin/countdown-engine" lock-pause 2>/dev/null || true

        # Avoid stacking locks (otherwise you would unlock twice).
        if pgrep -x swaylock >/dev/null 2>&1; then
          exit 0
        fi

        # -f so swaylock does not block swayidle; -e so an empty Enter does not count as a wrong password.
        exec ${pkgs.swaylock}/bin/swaylock -f -e -i ${./../../lockscreen/nixos.jpg}
      '';
    };
  };
}
