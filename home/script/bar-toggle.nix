{ ... }:

{
  home.file = {
    ".local/bin/bar-toggle" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Hide/show Waybar via SIGUSR1 (Waybar's own toggle: hide then show
        # again in the same spot; no restart so no layout flicker and no loss
        # of state in custom modules).
        #
        # ⚠️ The process name is NOT always `waybar`:
        #   - `programs.waybar.systemd.enable = true` (in use) -> Home-Manager
        #     wraps it as `.waybar-wrapped`, so `pkill -x waybar` does NOT match.
        #   - If systemd.enable is turned off later, the name is `waybar` again.
        # Try both instead of guessing.
        set -u

        killed=0
        for name in waybar .waybar-wrapped; do
          if pkill -x -SIGUSR1 "$name" 2>/dev/null; then
            killed=1
            break
          fi
        done

        if [ "$killed" -eq 0 ]; then
          notify-send -a bar-toggle -t 3000 "Waybar" \
            "Could not find the waybar process (tried both 'waybar' and '.waybar-wrapped')" \
            2>/dev/null || true
          exit 1
        fi

        # SIGUSR1 flips the state by itself; the script does not need (and should
        # not) predict whether it is hidden or shown — reading Waybar's state is redundant.
      '';
    };
  };
}
