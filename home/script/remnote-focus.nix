{ config, pkgs, ... }:

{
  home.file.".local/bin/remnote-focus" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import shutil
      import subprocess
      import sys
      from pathlib import Path

      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("remnote-focus: swaymsg is not in PATH")

      result = subprocess.run(
          [swaymsg, "-t", "get_tree"],
          check=True,
          capture_output=True,
          text=True,
      )
      tree = json.loads(result.stdout)

      def windows(node, workspace=None):
          if node.get("type") == "workspace":
              workspace = node.get("name")
          properties = node.get("window_properties") or {}
          if (properties.get("class") or "").casefold() == "remnote":
              yield node, workspace
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from windows(child, workspace)

      def focused_workspace(node):
          if node.get("type") == "workspace" and node.get("focused"):
              return node.get("name")
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  name = focused_workspace(child)
                  if name is not None:
                      return name
          return None

      matches = list(windows(tree))
      if matches:
          # Prefer a focused or visible RemNote window if there are duplicates.
          match = next((item for item in matches if item[0].get("focused")), None)
          if match is None:
              match = next((item for item in matches if item[0].get("visible")), matches[0])
          window, window_workspace = match
          criteria = f"[con_id={window['id']}]"

          if window.get("focused") and window.get("visible"):
              # Hide only when RemNote itself is focused.
              command = (
                  "scratchpad show"
                  if window.get("scratchpad_state") != "none"
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          elif window.get("scratchpad_state") != "none" and not window.get("visible"):
              # Restore hidden scratchpad windows onto the current workspace.
              subprocess.run([swaymsg, f"{criteria} scratchpad show"], check=True)
          else:
              workspace = focused_workspace(tree)
              if window_workspace != workspace:
                  # Bring RemNote from another workspace to the one we're using.
                  subprocess.run(
                      [swaymsg, f"{criteria} move container to workspace current"],
                      check=True,
                  )
              subprocess.run([swaymsg, f"{criteria} focus"], check=True)
      else:
          appimage = Path("${config.home.homeDirectory}/Apps/RemNote/RemNote.AppImage")
          if not appimage.is_file():
              sys.exit(f"RemNote AppImage not found: {appimage} (run setup-remnote first)")
          subprocess.Popen(
              ["${pkgs.appimage-run}/bin/appimage-run", str(appimage)],
              start_new_session=True,
          )
    '';
  };
}
