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
  home.file.".local/bin/swayr-rofi-menu" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import json
      import re
      import os
      import shutil
      import subprocess
      import sys
      from pathlib import Path

      rofi = "${pkgs.rofi}/bin/rofi"
      prompt = sys.argv[1] if len(sys.argv) > 1 else "Switch to window"
      rows = sys.stdin.buffer.read().splitlines()
      # Keep switch-window's default order; reverse only the quit menu so recent
      # windows are lower in the list. swayr puts the focused window last.
      if prompt.casefold().startswith("quit") and len(rows) > 1:
          rows = list(reversed(rows[:-1])) + rows[-1:]

      # Tiền tố [S]: cửa sổ nào XUẤT HIỆN trong menu scratchpad ($mod+m)
      # thì cũng có tiền tố [S] ở cả 2 menu swayr (kill + tổng). Điều kiện
      # chung duy nhất: scratchpad_state != "none" (ĐANG CẤT, visible=False).
      # Popup scratchpad đang hiện (visible=True) KHÔNG gắn — nó đang ngay
      # trước mắt, không có nguy cơ kill nhầm.
      in_scratchpad = set()
      swaymsg = shutil.which("swaymsg")
      if swaymsg:
          try:
              tree = json.loads(subprocess.run(
                  [swaymsg, "-t", "get_tree"],
                  check=True, capture_output=True, text=True,
              ).stdout)

              def collect_ids(node):
                  if node.get("type") in ("con", "floating_con"):
                      if node.get("scratchpad_state") not in (None, "none") and not node.get("visible"):
                          ident = node.get("app_id") or (node.get("window_properties") or {}).get("class") or ""
                          name = node.get("name") or (node.get("window_properties") or {}).get("title") or ""
                          if ident:
                              in_scratchpad.add(ident.casefold())
                          if name:
                              in_scratchpad.add(name.casefold())
                  for key in ("nodes", "floating_nodes"):
                      for child in node.get(key, []):
                          collect_ids(child)

              collect_ids(tree)
          except (subprocess.CalledProcessError, ValueError, OSError):
              pass

      display_rows = []
      icon_dirs = [Path(path) for path in ${builtins.toJSON iconDirs}]
      desktop_dirs = [Path(path) for path in ${builtins.toJSON desktopDirs}]
      for data_dir in os.environ.get("XDG_DATA_DIRS", "").split(":"):
          if data_dir:
              desktop_dirs.append(Path(data_dir) / "applications")
              for size in ("16x16", "22x22", "24x24", "32x32", "48x48", "64x64", "128x128", "256x256", "scalable"):
                  icon_dirs.append(Path(data_dir) / "icons" / "hicolor" / size / "apps")
              icon_dirs.append(Path(data_dir) / "pixmaps")
      icon_files = {}
      desktop_icons = {}

      # Build lookup tables from installed icons and .desktop metadata. This
      # handles app IDs such as "code" whose desktop entry names its icon "vscode".
      for directory in icon_dirs:
          try:
              for path in directory.iterdir():
                  if path.is_file() and path.suffix.lower() in (".png", ".svg", ".xpm", ".jpg"):
                      icon_files.setdefault(path.stem.casefold(), path)
          except OSError:
              pass

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
                              if key in ("Icon", "StartupWMClass"):
                                  values[key] = value
                      icon = values.get("Icon", "")
                      if icon:
                          if Path(icon).is_file():
                              icon_path = Path(icon)
                          else:
                              icon_path = icon_files.get(Path(icon).stem.casefold())
                          if icon_path:
                              desktop_icons.setdefault(desktop.stem.casefold(), icon_path)
                              wm_class = values.get("StartupWMClass", "")
                              if wm_class:
                                  desktop_icons.setdefault(wm_class.casefold(), icon_path)
                  except OSError:
                      pass
          except OSError:
              pass

      def find_icon(app_name):
          key = app_name.casefold()
          return icon_files.get(key) or desktop_icons.get(key)

      # swayr formats entries as "app_name — title\0icon\x1f/path".
      # Chrome PWA app IDs are generated hashes; use their title alone.
      pwa_id = re.compile(r"^(?:chrome|chromium)-[a-z0-9_-]{16,}(?:-[a-z0-9 _-]+)?$", re.I)
      for row in rows:
          label, separator, icon = row.partition(b"\0")
          text = label.decode("utf-8", "replace")
          app_name, delimiter, title = text.partition(" — ")
          if delimiter and pwa_id.fullmatch(app_name):
              label = title.encode("utf-8")
          # So khớp theo app_id HOẶC title (swayr hiển thị "app — title",
          # PWA chỉ hiện title) — khớp cái nào cũng gắn [S].
          haystacks = {app_name.casefold()}
          if delimiter:
              haystacks.add(title.casefold())
          else:
              haystacks.add(text.casefold())
          if haystacks & in_scratchpad:
              label = b"[S] " + label
          icon_path = icon.partition(b"icon\x1f")[2].decode("utf-8", "replace") if separator else ""
          if not icon_path or not Path(icon_path).is_file():
              found = find_icon(app_name)
              if found:
                  icon_path = str(found)
          row_for_menu = label
          if icon_path and Path(icon_path).is_file():
              row_for_menu += b"\0icon\x1f" + icon_path.encode("utf-8")
          display_rows.append(row_for_menu)

      result = subprocess.run(
          [rofi, "-dmenu", "-i", "-matching", "fuzzy", "-show-icons", "-format", "i", "-p", prompt],
          input=b"\n".join(display_rows) + (b"\n" if display_rows else b""),
          stdout=subprocess.PIPE,
          check=False,
      )
      if result.returncode != 0:
          sys.exit(result.returncode)

      try:
          selected = int(result.stdout.strip())
          sys.stdout.buffer.write(rows[selected] + b"\n")
      except (ValueError, IndexError):
          sys.exit(1)
    '';
  };
}
