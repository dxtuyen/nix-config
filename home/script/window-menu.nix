{ config, pkgs, ... }:

# window-menu — window menu for Sway, ONE engine shared by two keys:
#   $mod+Tab       -> window-menu              (all windows)
#   $mod+Shift+Tab -> window-menu --scratchpad (only [S] + [F])
# The [S]/[F] prefix is always shown in both menus, synced with the badge
# on Waybar (winmode script) so you can tell the window type: stashed in
# the scratchpad, floating popup, or regular tiled. Previously this menu called
# `rofi -show window` directly — a built-in mode, so prefixes could not be injected.
#
# Named per the repo's kebab-case convention (wallpaper-menu, power-menu, …).
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
      #   (default) ALL windows: scratchpad [S] + floating popup [F] + tiled.
      #       -> $mod+Tab
      #   --scratchpad  only [S] + [F]. -> $mod+Shift+Tab
      # One engine for both menus, so the [S]/[F] prefix is ALWAYS present in
      # both, matching the Waybar badge (winmode module).
      stashed_only = "--scratchpad" in sys.argv[1:]

      tree = json.loads(subprocess.run(
          [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
      ).stdout)

      def collect_windows(node, ws=None):
          # [S] = scratchpad member; [F] = floating popup (not in the
          # scratchpad); empty = tiled. Also record the ancestor workspace name —
          # the only clue to where the window is: stashed windows live under
          # workspace "__i3_scratch", popups under a real ws.
          # Tiled windows are only collected when NOT filtering (full menu $mod+Tab).
          if node.get("type") == "workspace":
              ws = node.get("name") or ws
          node_type = node.get("type")
          if node.get("scratchpad_state") not in (None, "none"):
              if node_type in ("con", "floating_con"):
                  yield (node, "S", ws)
          elif node_type == "floating_con":
              yield (node, "F", ws)
          elif not stashed_only and node_type == "con":
              yield (node, "", ws)
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from collect_windows(child, ws)

      found = list(collect_windows(tree))
      windows = [window for window, _, _ in found]
      kinds = {window["id"]: kind for window, kind, _ in found}
      window_ws = {window["id"]: ws for window, _, ws in found}
      if not windows:
          subprocess.run([
              shutil.which("notify-send") or "notify-send",
              "Scratchpad",
              ("No stashed or popup window" if stashed_only
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

          # [S] = scratchpad member · [F] = floating popup · (empty) = tiled.
          # Matches the [S]/[F] badge on Waybar (winmode module).
          # Tiled windows get no prefix — the old `rofi -show window`
          # had no prefixes either; keep the list uncluttered.
          kind = kinds.get(window["id"], "S")
          if kind:
              label = f"[{kind}] {label}"

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

      # Number entries only when several windows SHARE a name (e.g. 2 tabs with
      # the same title) so they can be told apart. The number goes at the END of
      # the display string, never between icon and label.
      rows = []
      for index, (label, row) in enumerate(rendered, start=1):
          if counts[label] > 1:
              label_bytes, separator, icon = row.partition(b"\0")
              row = label_bytes + f" ({index})".encode("utf-8") + (separator + icon if separator else b"")
          rows.append(row)

      # The menu is hand-written with swaymsg so it keeps con_id -> allows a
      # key to close the window. This menu serves BOTH $mod+Tab (all windows)
      # AND $mod+Shift+Tab (filtered --scratchpad), see sway.nix. The list
      # must be built manually instead of using `rofi -show window` because that
      # is a built-in rofi mode -> [S]/[F] prefixes cannot be injected.
      # dmenu-style search: -matching normal = exact substring match
      # (predictable; fuzzy matches scattered characters so typing feels chaotic),
      # -no-sort keeps the original list order, -no-custom only allows picking
      # real rows (free-form input is meaningless for a window picker).
      choice = subprocess.run(
          [
              "${pkgs.rofi}/bin/rofi", "-dmenu", "-i", "-matching", "normal",
              "-no-sort", "-no-custom", "-show-icons", "-format", "i",
              "-p", "Scratchpad" if stashed_only else "Windows",
              # Matches `rofi -show window`: Shift+Delete = close window.
              # Shift+Delete is already bound to kb-delete-entry (delete line) ->
              # must unset ("") first, otherwise rofi refuses and prints the red
              # line "Failed to set binding ...". Plain Delete too (it is bound
              # to kb-remove-char-forward) so it is not used.
              "-kb-delete-entry", "",
              "-kb-custom-1", "Shift+Delete",
              "-mesg",
              ("Enter: open / focus / pull to current ws · Shift+Delete: close this window"
               if stashed_only else
               "Enter: jump to window · Shift+Delete: close this window"),
          ],
          input=b"\n".join(rows) + (b"\n" if rows else b""),
          capture_output=True,
          check=False,
      )
      # rofi: 0 = Enter, 10 = custom-1 (Shift+Delete = kill), 1 = cancel.
      if choice.returncode not in (0, 10):
          sys.exit(0)
      try:
          window = windows[int(choice.stdout.strip())]
      except (ValueError, IndexError):
          sys.exit(0)  # -no-custom: no row matched -> treat as cancel

      if choice.returncode == 10:
          subprocess.run([swaymsg, f"[con_id={window['id']}] kill"],
                         check=False)
          sys.exit(0)

      # Workspace of the focused view — Enter needs to know whether the window
      # currently lives on "another ws".
      try:
          workspaces = json.loads(subprocess.run(
              [swaymsg, "-t", "get_workspaces"], check=True,
              capture_output=True, text=True).stdout)
          current_ws = next(w["name"] for w in workspaces if w.get("focused"))
      except (subprocess.CalledProcessError, ValueError, StopIteration, KeyError):
          current_ws = None

      SCRATCH_WS = "__i3_scratch"

      def enter_command(con_id, ws_of, ws_current):
          """Enter command for one menu row (pure -> unit-testable):
          - hidden in scratchpad -> reveal it;
          - filtered menu (--scratchpad): on another ws -> PULL it to the current
            ws then focus (this is the filtered menu's own behavior, $mod+Shift+Tab);
          - full menu (default): focus only, NEVER move the window, to keep the
            same "jump to" feel as the old `rofi -show window`.
          Returns a list of swaymsg commands (execution order)."""
          criteria = f"[con_id={con_id}]"
          if ws_of == SCRATCH_WS:
              return [f"{criteria} scratchpad show"]
          if not stashed_only:
              return [f"{criteria} focus"]
          if ws_of is None or ws_current is None or ws_of == ws_current:
              return [f"{criteria} focus"]
          return [
              f"{criteria} move container to workspace current",
              f"{criteria} focus",
          ]

      for command in enter_command(
              window["id"], window_ws.get(window["id"]), current_ws):
          subprocess.run([swaymsg, command], check=True)
    '';
  };
}
