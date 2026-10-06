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
          terminal = next((window for window in matches if window.get("focused")), matches[0])
          criteria = f"[con_id={terminal['id']}]"

          if terminal.get("focused"):
              # Toggle the focused terminal back into the scratchpad.
              command = (
                  "scratchpad show"
                  if terminal.get("scratchpad_state") not in (None, "none")
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          elif terminal.get("visible"):
              # Focus a visible terminal without changing its layout.
              subprocess.run([swaymsg, f"{criteria} focus"], check=True)
          elif terminal.get("scratchpad_state") not in (None, "none"):
              # Restore the hidden terminal on the current workspace.
              subprocess.run([swaymsg, f"{criteria} scratchpad show"], check=True)
          else:
              # Move terminals from other workspaces here before stashing them.
              subprocess.run(
                  [swaymsg, f"{criteria} move container to workspace current, "
                            "move scratchpad, scratchpad show"],
                  check=True,
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
