{ pkgs, ... }:

{
  home.file = {
    ".local/bin/yazi-open" = {
      executable = true;
      text = ''
        #!${pkgs.python3}/bin/python3
        # Toggle yazi in a small popup foot window — bound to $mod+y for quick file
        # picking / image add-remove. Same pattern as scratchpad-terminal:
        # focused -> stash to scratchpad; visible -> focus; hidden -> show here;
        # elsewhere/missing -> launch (or pull here as a scratchpad popup).
        import json
        import shutil
        import subprocess
        import sys

        app_id = "yazi-popup"
        swaymsg = shutil.which("swaymsg")
        if not swaymsg:
            sys.exit("yazi-open: swaymsg is not in PATH")

        tree = json.loads(subprocess.run(
            [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
        ).stdout)

        def find_yazi(node):
            if node.get("app_id") == app_id:
                yield node
            for key in ("nodes", "floating_nodes"):
                for child in node.get(key, []):
                    yield from find_yazi(child)

        matches = list(find_yazi(tree))
        if matches:
            window = next((w for w in matches if w.get("focused")), matches[0])
            criteria = f"[con_id={window['id']}]"
            if window.get("focused"):
                command = (
                    "scratchpad show"
                    if window.get("scratchpad_state") not in (None, "none")
                    else "move container to scratchpad"
                )
                subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
            elif window.get("visible"):
                subprocess.run([swaymsg, f"{criteria} focus"], check=True)
            elif window.get("scratchpad_state") not in (None, "none"):
                subprocess.run([swaymsg, f"{criteria} scratchpad show"], check=True)
            else:
                subprocess.run(
                    [swaymsg, f"{criteria} move container to workspace current, "
                              "move scratchpad, scratchpad show"],
                    check=True,
                )
        else:
            subprocess.Popen(
                ["${pkgs.foot}/bin/foot", f"--app-id={app_id}",
                 "--window-size-pixels=1000x700", "-e", "yazi", *sys.argv[1:]],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
      '';
    };
  };
}
