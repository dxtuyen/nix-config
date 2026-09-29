{ pkgs, ... }:

{
  home.file.".local/bin/scratchpad-menu" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import shutil
      import subprocess
      import sys

      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("scratchpad-menu: swaymsg is not in PATH")

      tree = json.loads(subprocess.run(
          [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
      ).stdout)

      def scratchpad_windows(node):
          if node.get("type") in ("con", "floating_con") and node.get("scratchpad_state") not in (None, "none"):
              yield node
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from scratchpad_windows(child)

      windows = list(scratchpad_windows(tree))
      if not windows:
          subprocess.run([
              shutil.which("notify-send") or "notify-send",
              "Scratchpad", "Không có cửa sổ nào đang được cất",
          ], check=False)
          sys.exit(0)

      def label(window):
          props = window.get("window_properties") or {}
          app = window.get("app_id") or props.get("class") or "Window"
          title = window.get("name") or props.get("title") or ""
          if title and title.casefold() != app.casefold():
              return f"{app} — {title}"
          return app

      labels = [label(window) for window in windows]
      counts = {}
      for item in labels:
          counts[item] = counts.get(item, 0) + 1
      rows = [
          f"{item} [{window['id']}]" if counts[item] > 1 else item
          for item, window in zip(labels, windows)
      ]

      choice = subprocess.run(
          ["${pkgs.rofi}/bin/rofi", "-dmenu", "-i", "-matching", "fuzzy", "-format", "i", "-p", "Scratchpad"],
          input="\n".join(rows) + "\n",
          capture_output=True,
          text=True,
          check=False,
      )
      if choice.returncode != 0:
          sys.exit(0)
      try:
          window = windows[int(choice.stdout.strip())]
      except (ValueError, IndexError):
          sys.exit("scratchpad-menu: invalid selection")

      criteria = f"[con_id={window['id']}]"
      command = "focus" if window.get("visible") else "scratchpad show"
      subprocess.run([swaymsg, f"{criteria} {command}"], check=True)
    '';
  };
}
