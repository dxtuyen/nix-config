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

          if window.get("focused"):
              # Đang focus: bấm mod+r lần nữa → cất về scratchpad (toggle).
              # Thuộc scratchpad ("fresh"/"changed") → scratchpad show = ẩn;
              # đã bị gỡ khỏi scratchpad ("none") → move container to scratchpad.
              command = (
                  "scratchpad show"
                  if window.get("scratchpad_state") not in (None, "none")
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          elif window.get("visible"):
              # Đang hiện trên workspace hiện tại (kể cả tiled chiếm trọn màn
              # hình hay fullscreen): chỉ focus, không re-float/đổi kích thước.
              subprocess.run([swaymsg, f"{criteria} focus"], check=True)
          elif window.get("scratchpad_state") not in (None, "none"):
              # Đang ẩn trong scratchpad: kéo về workspace hiện tại + focus.
              subprocess.run([swaymsg, f"{criteria} scratchpad show"], check=True)
          else:
              # Ở workspace khác (hoặc đã bị gỡ khỏi scratchpad): thành popup
              # scratchpad ở workspace HIỆN TẠI, size mặc định của Sway.
              # Phải "move ... workspace current" TRƯỚC, vì "move scratchpad"
              # trên cửa sổ ở ws khác sẽ kéo focus về workspace cũ của nó.
              subprocess.run(
                  [swaymsg, f"{criteria} move container to workspace current, "
                            "move scratchpad, scratchpad show"],
                  check=True,
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
