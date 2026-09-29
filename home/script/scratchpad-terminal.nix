{ pkgs, ... }:

{
  home.file.".local/bin/scratchpad-terminal" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import shutil
      import subprocess
      import sys

      app_id = "scratchpad-terminal"
      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("scratchpad-terminal: swaymsg is not in PATH")

      tree = json.loads(subprocess.run(
          [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
      ).stdout)

      def find_terminal(node):
          if node.get("app_id") == app_id:
              yield node
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from find_terminal(child)

      matches = list(find_terminal(tree))
      if matches:
          # Targeted scratchpad show toggles this terminal: hide it if visible,
          # otherwise restore it on the current workspace and focus it.
          terminal = next((window for window in matches if window.get("focused")), matches[0])
          if terminal.get("visible") and not terminal.get("focused"):
              command = "focus"
          else:
              command = "scratchpad show"
          subprocess.run(
              [swaymsg, f"[con_id={terminal['id']}] {command}"], check=True
          )
      else:
          # Lazy launch avoids keeping an unused terminal process alive.
          subprocess.Popen(
              ["${pkgs.foot}/bin/foot", f"--app-id={app_id}"],
              stdin=subprocess.DEVNULL,
              stdout=subprocess.DEVNULL,
              stderr=subprocess.DEVNULL,
              start_new_session=True,
          )
    '';
  };
}
