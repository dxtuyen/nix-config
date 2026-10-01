{ config, pkgs, ... }:

{
  # Chẩn đoán rule for_window: in app_id của các cửa sổ ĐANG MỞ rồi đối chiếu
  # với regex trong home/config/sway.nix. Dùng khi lên máy mới: app nào không
  # float/đóng workspace đúng → chạy script này, lấy app_id thật rồi sửa rule.
  # Không cần mở hết app: chỉ cần mở app đang nghi ngờ rồi chạy lại.
  home.file.".local/bin/app-id-check" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      """Đối chiếu app_id của cửa sổ đang mở với rule for_window trong sway.nix."""
      import json
      import re
      import shutil
      import subprocess
      import sys
      from pathlib import Path

      swaymsg = shutil.which("swaymsg")
      if not swaymsg:
          sys.exit("app-id-check: swaymsg is not in PATH")

      sway_nix = Path("${config.home.homeDirectory}/.config/sway/config")
      if not sway_nix.is_file():
          sys.exit(f"app-id-check: không thấy {sway_nix}")

      # Gom mọi rule app_id= / class= / title= từ extraConfig của sway.nix.
      rules = []
      for line in sway_nix.read_text(errors="replace").splitlines():
          for kind in ("app_id", "class", "title"):
              match = re.search(r'for_window\s*\[\s*' + kind + r'="((?:[^"\\]|\\.)*)"', line)
              if match:
                  try:
                      rules.append((kind, re.compile(match.group(1))))
                  except re.error as exc:
                      print(f"  [cảnh báo] regex {kind} không hợp lệ: {exc}", file=sys.stderr)

      tree = json.loads(subprocess.run(
          [swaymsg, "-t", "get_tree"], check=True, capture_output=True, text=True
      ).stdout)

      windows = []

      def walk(node):
          if node.get("type") in ("con", "floating_con"):
              props = node.get("window_properties") or {}
              windows.append((node.get("app_id") or "", props.get("class") or "",
                              node.get("name") or ""))
          for key in ("nodes", "floating_nodes"):
              for child in node.get(key, []):
                  walk(child)

      walk(tree)
      if not windows:
          sys.exit("app-id-check: không có cửa sổ nào đang mở.")

      print(f"Đã đọc {len(rules)} rule từ {sway_nix}\n")
      unmatched = []
      seen = set()
      for app_id, wm_class, title in windows:
          if (app_id, title) in seen:
              continue
          seen.add((app_id, title))
          # class rỗng với app native Wayland (sway(5): class chỉ có với X11).
          haystacks = {"app_id": {app_id.casefold()}, "class": {wm_class.casefold()}, "title": {title.casefold()}}
          haystacks["class"].discard("")
          haystacks["app_id"].discard("")
          hit = [kind for kind, rx in rules if any(rx.search(v) for v in haystacks[kind])]
          flag = "  " if hit else "!!"
          label = app_id or f"(class={wm_class})"
          print(f"{flag} {label}")
          if hit:
              print(f"     khớp: {', '.join(sorted(set(hit)))}")
          else:
              unmatched.append(label)
              print("     KHÔNG khớp rule nào — thử:")
              print(f'       for_window [app_id="(?i)^{re.escape(app_id)}$"] <hành động>')

      if unmatched:
          print(f"\n{len(unmatched)} cửa sổ chưa có rule: {' '.join(unmatched)}")
          print("Không phải lỗi — chỉ là app chưa cần cấu hình riêng.")
      else:
          print("\nMọi cửa sổ đang mở đều khớp ít nhất một rule.")
    '';
  };
}
