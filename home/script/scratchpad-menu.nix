{ config, pkgs, ... }:

let
  iconSizes = [
    "16x16"
    "22x22"
    "24x24"
    "32x32"
    "48x48"
    "64x64"
    "scalable"
  ];
  iconDirs =
    map (size: "${config.home.homeDirectory}/.local/share/icons/hicolor/${size}/apps") iconSizes
    ++ map (
      size: "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/${size}/apps"
    ) iconSizes
    ++ map (size: "/run/current-system/sw/share/icons/hicolor/${size}/apps") iconSizes
    ++ [
      "/run/current-system/sw/share/icons/Adwaita/48x48/apps"
      "/run/current-system/sw/share/icons/Adwaita/scalable/apps"
      "/run/current-system/sw/share/pixmaps"
    ];
  desktopDirs = [
    "${config.home.homeDirectory}/.local/share/applications"
    "/etc/profiles/per-user/${config.home.username}/share/applications"
    "/run/current-system/sw/share/applications"
  ];
in
{
  home.file.".local/bin/scratchpad-menu" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import os
      import re
      import shutil
      import subprocess
      import sys
      from pathlib import Path

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

      icon_dirs = [Path(path) for path in ${builtins.toJSON iconDirs}]
      desktop_dirs = [Path(path) for path in ${builtins.toJSON desktopDirs}]
      for data_dir in os.environ.get("XDG_DATA_DIRS", "").split(":"):
          if data_dir:
              desktop_dirs.append(Path(data_dir) / "applications")
              for size in ("16x16", "22x22", "24x24", "32x32", "48x48", "64x64", "128x128", "256x256", "scalable"):
                  icon_dirs.append(Path(data_dir) / "icons" / "hicolor" / size / "apps")
              icon_dirs.append(Path(data_dir) / "pixmaps")

      icon_files = {}
      for directory in icon_dirs:
          try:
              for path in directory.iterdir():
                  if path.is_file() and path.suffix.lower() in (".png", ".svg", ".xpm", ".jpg"):
                      icon_files.setdefault(path.stem.casefold(), path)
          except OSError:
              pass

      app_info = {}
      for directory in desktop_dirs:
          try:
              files = directory.glob("*.desktop")
              for desktop in files:
                  try:
                      values = {}
                      in_main_section = False
                      for line in desktop.read_text(errors="replace").splitlines():
                          if line.startswith("["):
                              in_main_section = line == "[Desktop Entry]"
                          elif in_main_section and "=" in line:
                              key, value = line.split("=", 1)
                              if key in ("Name", "Icon", "StartupWMClass"):
                                  values[key] = value

                      icon = values.get("Icon", "")
                      if icon:
                          icon_path = Path(icon) if Path(icon).is_file() else icon_files.get(Path(icon).stem.casefold())
                      else:
                          icon_path = None
                      info = {"name": values.get("Name", ""), "icon": icon_path}
                      app_info.setdefault(desktop.stem.casefold(), info)
                      wm_class = values.get("StartupWMClass", "").casefold()
                      if wm_class:
                          app_info.setdefault(wm_class, info)
                  except OSError:
                      pass
          except OSError:
              pass

      pwa_id = re.compile(r"^(?:chrome|chromium)-[a-z0-9_-]{16,}(?:-[a-z0-9 _-]+)?$", re.I)

      def window_row(window):
          props = window.get("window_properties") or {}
          app_id = window.get("app_id") or ""
          wm_class = props.get("class") or ""
          title = window.get("name") or props.get("title") or ""
          entry = app_info.get(app_id.casefold()) or app_info.get(wm_class.casefold()) or {}
          app_name = entry.get("name") or app_id or wm_class or "Window"

          if pwa_id.fullmatch(app_id):
              label = title or app_name
          elif title and title.casefold() != app_name.casefold():
              label = f"{app_name} — {title}"
          else:
              label = app_name

          icon_path = entry.get("icon")
          if not icon_path:
              icon_path = icon_files.get(app_id.casefold()) or icon_files.get(wm_class.casefold())
          row = label.encode("utf-8")
          if icon_path and Path(icon_path).is_file():
              row += b"\0icon\x1f" + str(icon_path).encode("utf-8")
          return label, row

      rendered = [window_row(window) for window in windows]
      labels = [label for label, _ in rendered]
      counts = {}
      for label in labels:
          counts[label] = counts.get(label, 0) + 1

      rows = []
      for index, (label, row) in enumerate(rendered, start=1):
          if counts[label] > 1:
              label_bytes, separator, icon = row.partition(b"\0")
              suffix = f" [{index}]".encode("utf-8")
              row = label_bytes + suffix + (separator + icon if separator else b"")
          rows.append(row)

      choice = subprocess.run(
          ["${pkgs.rofi}/bin/rofi", "-dmenu", "-i", "-matching", "fuzzy", "-show-icons", "-format", "i", "-p", "Scratchpad"],
          input=b"\n".join(rows) + (b"\n" if rows else b""),
          capture_output=True,
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
