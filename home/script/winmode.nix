{ pkgs, ... }:

# Winmode: badge showing the TYPE of the focused window on Waybar — [S] = scratchpad,
# [F] = floating popup, empty = tiled (module hidden). It is a SEPARATE small pill
# sitting RIGHT AFTER the title (the stock `sway/window` module is kept; the title
# is not rewritten). Why it exists: the 2 floating types look identical but use
# DIFFERENT keys ($mod+minus only toggles the scratchpad).
#
# Latency tuned so the badge matches the title almost instantly (old ~90ms):
#   - `status` (Waybar spawns it every update): shell + jq (~7ms) instead of
#     python3 (~62ms).
#   - `watch` (daemon): signal via the builtin `kill` instead of `pkill` scanning
#     /proc (~23ms per event).
{
  home.file.".local/bin/winmode" = {
    executable = true;
    text = ''
      #!/bin/sh
      # winmode status|watch — focused window type badge for Waybar (signal 9).
      #   status: print JSON {"text": "[S]|[F]|<empty>", "class": ..., "tooltip": ...}
      #   watch : listen for Sway window events -> send SIGRTMIN+9 to Waybar.
      # Uses absolute store paths (swaymsg/jq) -> no PATH dependency.
      SWAYMSG=${pkgs.sway}/bin/swaymsg
      JQ=${pkgs.jq}/bin/jq

      status() {
        tree=$("$SWAYMSG" -t get_tree 2>/dev/null) || tree=""
        if [ -z "$tree" ]; then
          # No Sway / IPC error -> empty text, module hides itself (hide-empty-text).
          printf '%s\n' '{"text":"","class":"tiled","tooltip":""}'
          return 0
        fi
        printf '%s' "$tree" | "$JQ" -c '
          [ paths as $p | getpath($p) | objects | select(.focused == true)
          | { title: ((.name // "") | gsub("\\n"; " ") | sub("^ +"; "") | sub(" +$"; "")),
              scratchpad: (.scratchpad_state // "none"),
              floating: ($p | index("floating_nodes") != null) } ]
          | first as $w
          | if $w == null then {text:"",class:"tiled",tooltip:""}
            elif $w.scratchpad != "none" then
              {text:"[S]", class:"s",
               tooltip:("scratchpad — $mod+equal show one, $mod+Shift+equal show all"
                        + (if $w.title != "" then " · " + $w.title else "" end))}
            elif $w.floating then
              {text:"[F]", class:"f",
               tooltip:("popup floating — $mod+Shift+minus stash"
                        + (if $w.title != "" then " · " + $w.title else "" end))}
            else {text:"",class:"tiled",tooltip:""}
            end'
      }

      watch() {
        # Waybar PID: probe once; probe again when kill fails (Waybar restarted).
        # Do NOT use `pgrep -x`: Waybar's real comm is `.waybar-wrapped` (set by
        # the home-manager wrapper) so -x never matches -> no signal delivered.
        pid=$(pgrep waybar 2>/dev/null | head -n1)
        # swaymsg exits (Sway died) -> loop stops -> systemd Restart=always
        # revives it; when sway-session.target stops the service stops too (PartOf).
        # `workspace` events are REQUIRED: switching to an EMPTY workspace makes no
        # window gain focus -> sway emits only `workspace` (no `window` event), so
        # with `window` alone the stale [S]/[F] badge stayed next to the cleared title.
        "$SWAYMSG" -m -t subscribe '["window","workspace"]' | while read -r _line; do
          # Any window/workspace event (focus/move/close, ws switch) can change the
          # state; sending a signal is far cheaper than parsing JSON on every line.
          if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
            pid=$(pgrep waybar 2>/dev/null | head -n1)
          fi
          [ -n "$pid" ] && kill -s RTMIN+9 "$pid" 2>/dev/null
        done
      }

      case "''${1:-}" in
        status) status ;;
        watch) watch ;;
        *) printf '%s\n' 'usage: winmode status|watch' >&2; exit 2 ;;
      esac
    '';
  };

  # Daemon listening on the Sway IPC — run via systemd like the repo's other
  # watchers (auto-restart, journald logging, stops with the Sway session via
  # sway-session.target).
  systemd.user.services.winmode-watch = {
    Unit = {
      Description = "Winmode: notify Waybar on Sway window/workspace changes ([S]/[F] indicator)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH is only needed for `pgrep` (swaymsg/jq use absolute store paths).
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "always";
      RestartSec = 2;
      ExecStart = "%h/.local/bin/winmode watch";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
