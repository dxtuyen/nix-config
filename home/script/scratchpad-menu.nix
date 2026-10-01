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

      def scratchpad_windows(node, ws=None):
          # [S] = thành viên scratchpad; [F] = popup floating (không thuộc
          # scratchpad). Ghi thêm tên workspace tổ tiên — dấu hiệu duy nhất
          # biết cửa sổ đang ở đâu: đang ẩn trong scratchpad thì nằm dưới
          # workspace "__i3_scratch", còn popup thì nằm dưới ws thật của nó.
          if node.get("type") == "workspace":
              ws = node.get("name") or ws
          node_type = node.get("type")
          if node.get("scratchpad_state") not in (None, "none"):
              if node_type in ("con", "floating_con"):
                  yield (node, "S", ws)
          elif node_type == "floating_con":
              yield (node, "F", ws)
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  yield from scratchpad_windows(child, ws)

      found = list(scratchpad_windows(tree))
      windows = [window for window, _, _ in found]
      kinds = {window["id"]: kind for window, kind, _ in found}
      window_ws = {window["id"]: ws for window, _, ws in found}
      if not windows:
          subprocess.run([
              shutil.which("notify-send") or "notify-send",
              "Scratchpad", "Không có cửa sổ nào đang cất hay popup",
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

          # [S] thành viên scratchpad · [F] popup floating. Đồng nhất
          # với huy hiệu [S]/[F] trên Waybar (module winmode).
          label = f"[{kinds.get(window['id'], 'S')}] {label}"

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

      # Chỉ đánh số khi có nhiều cửa sổ TRÙNG tên (vd 2 tab cùng tiêu đề), để
      # phân biệt được. Số đặt CUỐI chuỗi hiển thị, KHÔNG chèn vào giữa icon.
      rows = []
      for index, (label, row) in enumerate(rendered, start=1):
          if counts[label] > 1:
              label_bytes, separator, icon = row.partition(b"\0")
              row = label_bytes + f" ({index})".encode("utf-8") + (separator + icon if separator else b"")
          rows.append(row)

      # Menu tự viết bằng swaymsg nên giữ được con_id -> thêm phím đóng cửa
      # sổ. Menu $mod+Shift+m giờ là `rofi -show window` mặc định nên không
      # phải làm gì thêm (Shift+Delete của rofi đã tự đóng cửa sổ được).
      # Tìm kiếm kiểu dmenu: -matching normal = khớp chuỗi con nguyên vẹn
      # (dự đoán được; fuzzy khớp ký tự rải rác nên cảm giác loạn khi gõ),
      # -no-sort giữ nguyên thứ tự danh sách, -no-custom chỉ cho chọn dòng
      # thật (input tự do vô nghĩa với menu chọn cửa sổ).
      choice = subprocess.run(
          [
              "${pkgs.rofi}/bin/rofi", "-dmenu", "-i", "-matching", "normal",
              "-no-sort", "-no-custom", "-show-icons", "-format", "i",
              "-p", "Scratchpad",
              # Đồng bộ với `rofi -show window`: Shift+Delete = đóng cửa sổ.
              # Shift+Delete mặc định đã gán cho kb-delete-entry (xoá dòng) →
              # phải unset ("") trước, nếu không rofi từ chối và in dòng đỏ
              # "Failed to set binding ...". Delete trần cũng vậy (đã gán cho
              # kb-remove-char-forward) nên không dùng.
              "-kb-delete-entry", "",
              "-kb-custom-1", "Shift+Delete",
              "-mesg", "Enter: mở / focus / kéo về ws hiện tại · Shift+Delete: đóng cửa sổ này",
          ],
          input=b"\n".join(rows) + (b"\n" if rows else b""),
          capture_output=True,
          check=False,
      )
      # rofi: 0 = Enter, 10 = custom-1 (Shift+Delete = kill), 1 = hủy.
      if choice.returncode not in (0, 10):
          sys.exit(0)
      try:
          window = windows[int(choice.stdout.strip())]
      except (ValueError, IndexError):
          sys.exit(0)  # -no-custom: không có dòng nào khớp → coi như hủy

      if choice.returncode == 10:
          subprocess.run([swaymsg, f"[con_id={window['id']}] kill"],
                         check=False)
          sys.exit(0)

      # Workspace hiện tại — Enter cần biết cửa sổ có đang "ở ws khác" không.
      try:
          workspaces = json.loads(subprocess.run(
              [swaymsg, "-t", "get_workspaces"], check=True,
              capture_output=True, text=True).stdout)
          current_ws = next(w["name"] for w in workspaces if w.get("focused"))
      except (subprocess.CalledProcessError, ValueError, StopIteration, KeyError):
          current_ws = None

      SCRATCH_WS = "__i3_scratch"

      def enter_command(con_id, ws_of, ws_current):
          """Lệnh Enter cho 1 dòng menu (thuần → unit-test được):
          - ẩn trong scratchpad → mở ra;
          - ở workspace khác → KÉO về workspace hiện tại rồi focus;
          - cùng workspace (hoặc không rõ) → chỉ focus.
          Trả về danh sách lệnh swaymsg (thứ tự thực thi)."""
          criteria = f"[con_id={con_id}]"
          if ws_of == SCRATCH_WS:
              return [f"{criteria} scratchpad show"]
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
