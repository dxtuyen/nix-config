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
          # A focused terminal is hidden even if it was toggled out of floating
          # mode. Otherwise restore it on this workspace as a centered popup.
          terminal = next((window for window in matches if window.get("focused")), matches[0])
          criteria = f"[con_id={terminal['id']}]"
          if terminal.get("focused"):
              command = (
                  "scratchpad show"
                  if terminal.get("scratchpad_state") != "none"
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          else:
              commands = []
              if not terminal.get("visible"):
                  commands.append(
                      "scratchpad show"
                      if terminal.get("scratchpad_state") != "none"
                      else "move container to workspace current"
                  )
              commands.extend([
                  "floating enable",
                  "resize set width 65 ppt height 60 ppt",
                  "move position center",
                  "focus",
              ])
              subprocess.run(
                  [swaymsg, f"{criteria} " + ", ".join(commands)], check=True
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
