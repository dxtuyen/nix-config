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

      def windows(node):
          properties = node.get("window_properties") or {}
          wm_class = (properties.get("class") or "").casefold()
          app_id = (node.get("app_id") or "").casefold()
          if "remnote" in wm_class or "remnote" in app_id:
              yield node
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from windows(child)

      matches = list(windows(tree))
      if matches:
          # Prefer a focused or visible RemNote window if there are duplicates.
          match = next((item for item in matches if item.get("focused")), None)
          if match is None:
              match = next((item for item in matches if item.get("visible")), matches[0])
          window = match
          criteria = f"[con_id={window['id']}]"

          if window.get("focused") and window.get("visible"):
              # Hide only when RemNote itself is focused.
              command = (
                  "scratchpad show"
                  if window.get("scratchpad_state") != "none"
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          else:
              commands = []
              if not window.get("visible"):
                  # Restore it here whether it is hidden in the scratchpad or
                  # sitting on another workspace.
                  commands.append(
                      "scratchpad show"
                      if window.get("scratchpad_state") != "none"
                      else "move container to workspace current"
                  )
              # Reapply popup geometry in case a manual floating toggle changed
              # the window since the manage rule first ran.
              commands.extend([
                  "floating enable",
                  "resize set width 65 ppt height 75 ppt",
                  "move position center",
                  "focus",
              ])
              subprocess.run(
                  [swaymsg, f"{criteria} " + ", ".join(commands)], check=True
              )
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
