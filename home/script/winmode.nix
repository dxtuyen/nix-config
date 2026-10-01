{ pkgs, ... }:

# Winmode: chỉ báo LOẠI cửa sổ đang focus trên Waybar — [S] = scratchpad,
# [F] = popup floating, rỗng = tiled (Waybar ẩn module). Lý do tồn tại: 2 loại
# floating trông giống hệt nhau trên màn nhưng phím thao tác KHÁC nhau
# ($mod+minus chỉ toggle scratchpad). Cập nhật event-driven: daemon
# `winmode watch` nghe sự kiện window của Sway rồi báo Waybar (SIGRTMIN+9)
# → không poll, ~0% CPU khi chờ, không tốn pin.
{
  home.file.".local/bin/winmode" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      # winmode status|watch — chỉ báo mode cửa sổ focus cho Waybar (signal 9).
      #   status: in JSON {"text": "[S]|[F]|<rỗng>", "class": ..., "tooltip": ...}
      #   watch : nghe sự kiện window của Sway → pkill -RTMIN+9 waybar.
      import json
      import subprocess
      import sys

      SIGNAL = "-RTMIN+9"


      def find_focused(node, in_floating=False):
          """Trả về (node đang focus, có nằm trong floating_nodes) hoặc None."""
          if node.get("focused"):
              return node, in_floating
          for child in node.get("nodes", []):
              hit = find_focused(child, in_floating)
              if hit is not None:
                  return hit
          for child in node.get("floating_nodes", []):
              hit = find_focused(child, True)
              if hit is not None:
                  return hit
          return None


      def status():
          try:
              tree = json.loads(subprocess.check_output(
                  ["swaymsg", "-t", "get_tree"], text=True))
              hit = find_focused(tree)
          except Exception:
              hit = None  # không có Sway / IPC lỗi → in rỗng, module ẩn
          if hit is None:
              print(json.dumps({"text": "", "class": "tiled", "tooltip": ""}))
              return
          node, in_floating = hit
          state = node.get("scratchpad_state") or "none"
          if state != "none":
              out = {
                  "text": "[S]",
                  "class": "s",
                  "tooltip": "Focus: scratchpad — $mod+minus ẩn/hiện · $mod+Shift+minus cất lại",
              }
          elif in_floating:
              out = {
                  "text": "[F]",
                  "class": "f",
                  "tooltip": "Focus: popup floating — $mod+Shift+minus cất vào scratchpad · $mod+Shift+q hoặc Ctrl+Delete trong $mod+m để đóng",
              }
          else:
              out = {"text": "", "class": "tiled", "tooltip": ""}
          print(json.dumps(out, ensure_ascii=False))


      def watch():
          # Sway chết → swaymsg thoát → watch thoát → systemd (Restart=always)
          # hồi sinh; sway-session.target dừng thì service dừng theo (PartOf).
          proc = subprocess.Popen(
              ["swaymsg", "-m", "-t", "subscribe", '["window"]'],
              stdout=subprocess.PIPE, text=True, bufsize=1,
          )
          for _line in proc.stdout:
              # Mọi sự kiện window đều báo: focus/move/close đều làm đổi trạng
              # thái được; pkill còn rẻ hơn tự phân tích JSON từng dòng.
              subprocess.run(["pkill", SIGNAL, "waybar"], check=False)
          sys.exit(proc.wait())


      if __name__ == "__main__":
          cmd = sys.argv[1] if len(sys.argv) > 1 else ""
          if cmd == "status":
              status()
          elif cmd == "watch":
              watch()
          else:
              print("usage: winmode status|watch", file=sys.stderr)
              sys.exit(2)
    '';
  };

  # Daemon nghe Sway IPC — chạy qua systemd như watcher khác của repo
  # (tự hồi sinh, log journald, dừng theo phiên Sway qua sway-session.target).
  systemd.user.services.winmode-watch = {
    Unit = {
      Description = "Winmode: notify Waybar on Sway window focus changes ([S]/[F] indicator)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # PATH cho swaymsg + pkill.
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "always";
      RestartSec = 2;
      ExecStart = "%h/.local/bin/winmode watch";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}