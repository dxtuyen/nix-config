{ pkgs, ... }:

{
  home.file.".local/bin/obsidian-focus" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      # obsidian-focus ($mod+o): logic y hệt remnote-focus ($mod+r).
      # Chưa chạy → khởi động; đang focus → cất về scratchpad (toggle);
      # đang hiện → chỉ focus; ẩn trong scratchpad / ở ws khác → kéo về ws hiện tại.
      import json
      import shutil
      import subprocess
      import sys

      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("obsidian-focus: swaymsg is not in PATH")

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
          if "obsidian" in wm_class or "obsidian" in app_id:
              yield node
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from windows(child)

      matches = list(windows(tree))
      if matches:
          # Prefer a focused or visible Obsidian window if there are duplicates.
          match = next((item for item in matches if item.get("focused")), None)
          if match is None:
              match = next((item for item in matches if item.get("visible")), matches[0])
          window = match
          criteria = f"[con_id={window['id']}]"

          if window.get("focused"):
              # Đang focus: bấm mod+o lần nữa → cất về scratchpad (toggle).
              # Thuộc scratchpad ("fresh"/"changed") → scratchpad show = ẩn;
              # đã bị gỡ khỏi scratchpad ("none") → move container to scratchpad.
              command = (
                  "scratchpad show"
                  if window.get("scratchpad_state") not in (None, "none")
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          elif window.get("visible"):
              # Đang hiện trên workspace hiện tại (kể cả tiled/fullscreen): chỉ focus.
              subprocess.run([swaymsg, f"{criteria} focus"], check=True)
          elif window.get("scratchpad_state") not in (None, "none"):
              # Đang ẩn trong scratchpad: kéo về workspace hiện tại + focus.
              subprocess.run([swaymsg, f"{criteria} scratchpad show"], check=True)
          else:
              # Ở workspace khác: thành popup scratchpad ở workspace HIỆN TẠI.
              # Phải "move ... workspace current" TRƯỚC, vì "move scratchpad"
              # trên cửa sổ ở ws khác sẽ kéo focus về workspace cũ của nó.
              subprocess.run(
                  [swaymsg, f"{criteria} move container to workspace current, "
                            "move scratchpad, scratchpad show"],
                  check=True,
              )
      else:
          subprocess.Popen(
              ["${pkgs.obsidian}/bin/obsidian"],
              start_new_session=True,
          )
    '';
  };
}
