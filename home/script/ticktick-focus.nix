{ pkgs, ... }:

{
  home.file.".local/bin/ticktick-focus" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      # ticktick-focus ($mod+i): logic y hệt remnote-focus/obsidian-focus.
      # TickTick là PWA Chrome (app_id chrome-<id>-Default) → matcher theo
      # extension-id 32 ký tự để bền nếu Chrome đổi hậu tố profile.
      # Chưa mở → launch --app-id (cửa sổ map vào rule float 1000×700 giữa
      # màn hình trong sway.nix); đang focus → cất về scratchpad (toggle);
      # đang hiện → chỉ focus; ẩn/ở ws khác → kéo về ws hiện tại.
      import json
      import shutil
      import subprocess
      import sys

      APP_ID = "cfammbeebmjdpoppachopcohfchgjapd"

      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("ticktick-focus: swaymsg is not in PATH")

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
          if APP_ID in wm_class or APP_ID in app_id:
              yield node
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from windows(child)

      matches = list(windows(tree))
      if matches:
          # Prefer a focused or visible TickTick window if there are duplicates.
          match = next((item for item in matches if item.get("focused")), None)
          if match is None:
              match = next((item for item in matches if item.get("visible")), matches[0])
          window = match
          criteria = f"[con_id={window['id']}]"

          if window.get("focused"):
              # Đang focus: bấm mod+q lần nữa → cất về scratchpad (toggle).
              # Thuộc scratchpad ("fresh"/"changed") → scratchpad show = ẩn;
              # còn float trên workspace ("none") → move container to scratchpad.
              command = (
                  "scratchpad show"
                  if window.get("scratchpad_state") not in (None, "none")
                  else "move container to scratchpad"
              )
              subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
          elif window.get("visible"):
              # Đang hiện trên workspace hiện tại (float 1000×700): chỉ focus.
              subprocess.run([swaymsg, f"{criteria} focus"], check=True)
          elif window.get("scratchpad_state") not in (None, "none"):
              # Đang ẩn trong scratchpad: kéo về + focus.
              subprocess.run([swaymsg, f"{criteria} scratchpad show"], check=True)
          else:
              # Ở workspace khác (float trên ws khác): về ws HIỆN TẠI rồi hiện.
              subprocess.run(
                  [swaymsg, f"{criteria} move container to workspace current, "
                            "move scratchpad, scratchpad show"],
                  check=True,
              )
      else:
          # Launch PWA qua --app-id; --no-first-run chặn luồng setup profile mới.
          subprocess.Popen(
              [
                  "${pkgs.google-chrome}/bin/google-chrome",
                  "--profile-directory=Default",
                  f"--app-id={APP_ID}",
                  "--no-first-run",
                  "--no-default-browser-check",
              ],
              start_new_session=True,
          )
    '';
  };
}
