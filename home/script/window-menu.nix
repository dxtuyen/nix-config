{ config, pkgs, ... }:

# window-menu — one engine, two keys:
#   $mod+Tab       -> window-menu --scratchpad (hidden windows only)
#   $mod+Shift+Tab -> window-menu              (visible windows only)
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
  home.file.".local/bin/window-menu" = {
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
          sys.exit("window-menu: swaymsg is not in PATH")

      # window-menu [--scratchpad]
      #   default: visible windows only. -> $mod+Shift+Tab
      #   --scratchpad: hidden windows only. -> $mod+Tab
      # No overlap: each window appears in exactly one menu.
      stashed_only = "--scratchpad" in sys.argv[1:]

      tree = json.loads(subprocess.run(
          [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
      ).stdout)

      def collect_windows(node, ws=None):
          # Track the ancestor workspace (hidden windows live under __i3_scratch).
          # --scratchpad: hidden only (scratchpad_state != "none", not visible).
          # default: visible only (hidden scratchpad excluded).
          if node.get("type") == "workspace":
              ws = node.get("name") or ws
          node_type = node.get("type")
          if node_type in ("con", "floating_con"):
              in_scratch = node.get("scratchpad_state") not in (None, "none")
              visible = bool(node.get("visible"))
              if in_scratch:
                  if stashed_only and not visible:
                      yield (node, ws)
                  elif not stashed_only and visible:
                      yield (node, ws)
              elif not stashed_only:
                  yield (node, ws)
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from collect_windows(child, ws)

      found = list(collect_windows(tree))
      windows = [window for window, _ in found]
      window_ws = {window["id"]: ws for window, ws in found}
      if not windows:
          subprocess.run([
              shutil.which("notify-send") or "notify-send",
              "Scratchpad",
              ("No hidden scratchpad window" if stashed_only
               else "No open window"),
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

      # Number duplicate labels only (number at the end, after the icon).
      rows = []
      for index, (label, row) in enumerate(rendered, start=1):
          if counts[label] > 1:
              label_bytes, separator, icon = row.partition(b"\0")
              row = label_bytes + f" ({index})".encode("utf-8") + (separator + icon if separator else b"")
          rows.append(row)

      # Hand-built list (keeps con_id for kill; `rofi -show window` can't inject prefixes).
      # Serves both keys, see sway.nix. Exact substring match, list order kept.
      choice = subprocess.run(
          [
              "${pkgs.rofi}/bin/rofi", "-dmenu", "-i", "-matching", "normal",
              "-no-sort", "-no-custom", "-show-icons", "-format", "i",
              "-p", "Scratchpad" if stashed_only else "Windows",
              # Shift+Delete = close (must unset kb-delete-entry first or rofi errors).
              "-kb-delete-entry", "",
              "-kb-custom-1", "Shift+Delete",
              # Shift+Enter = pull here (must unset kb-accept-alt first; rofi exits 11).
              "-kb-accept-alt", "",
              "-kb-custom-2", "Shift+Return",
              "-mesg",
              ("Enter: show on this workspace · Shift+Delete: close this window"
               if stashed_only else
               "Enter: jump to window · Shift+Enter: pull here · Shift+Delete: close"),
          ],
          input=b"\n".join(rows) + (b"\n" if rows else b""),
          capture_output=True,
          check=False,
      )
      # rofi: 0 = Enter, 10 = custom-1 (Shift+Delete = kill),
      # 11 = custom-2 (Shift+Enter = pull here), 1 = cancel.
      if choice.returncode not in (0, 10, 11):
          sys.exit(0)
      try:
          window = windows[int(choice.stdout.strip())]
      except (ValueError, IndexError):
          sys.exit(0)  # -no-custom: no row matched -> treat as cancel

      if choice.returncode == 10:
          subprocess.run([swaymsg, f"[con_id={window['id']}] kill"],
                         check=False)
          sys.exit(0)

      # Current workspace (to detect windows on other workspaces).
      try:
          workspaces = json.loads(subprocess.run(
              [swaymsg, "-t", "get_workspaces"], check=True,
              capture_output=True, text=True).stdout)
          current_ws = next(w["name"] for w in workspaces if w.get("focused"))
      except (subprocess.CalledProcessError, ValueError, StopIteration, KeyError):
          current_ws = None

      SCRATCH_WS = "__i3_scratch"

      def enter_command(con_id, ws_of, ws_current, pull=False):
          """Enter command for one menu row (pure -> unit-testable):
          hidden -> scratchpad show; Shift+Enter on another ws -> move here + focus;
          plain Enter -> focus only, never moves."""
          criteria = f"[con_id={con_id}]"
          if ws_of == SCRATCH_WS:
              return [f"{criteria} scratchpad show"]
          want_pull = pull or stashed_only
          if want_pull:
              if ws_of is not None and ws_current is not None and ws_of != ws_current:
                  return [
                      f"{criteria} move container to workspace current",
                      f"{criteria} focus",
                  ]
          return [f"{criteria} focus"]

      pull_here = choice.returncode == 11
      for command in enter_command(
              window["id"], window_ws.get(window["id"]), current_ws,
              pull=pull_here):
          subprocess.run([swaymsg, command], check=True)
    '';
  };
}
