{ pkgs, ... }:

# Winmode: tiêu đề cửa sổ đang focus trên Waybar (THAY sway/window) — tiled =
# tiêu đề trần, scratchpad = "[S] tiêu đề", popup floating = "[F] tiêu đề"
# (tiền tố nằm TRƯỚC chữ, cùng một pill). Lý do gộp: Waybar không có cách gắn
# prefix vào sway/window, nên script tự ghép tiền tố + title. Phân biệt 2 loại
# floating vì trông giống hệt nhau nhưng phím thao tác KHÁC nhau ($mod+minus
# chỉ toggle scratchpad). Cập nhật event-driven: daemon `winmode watch` nghe sự
# kiện window của Sway rồi báo Waybar (SIGRTMIN+9) → không poll, ~0% CPU khi
# chờ, không tốn pin.
{
  home.file.".local/bin/winmode" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      # winmode status|watch — tiêu đề cửa sổ focus cho Waybar (signal 9).
      #   status: in JSON {"text": "<title>|[S] <title>|[F] <title>", "class": ...}
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
          title = (node.get("name") or "").replace("\n", " ").strip()
          # Tiền tố dính tiêu đề trong CÙNG pill — Waybar không có chỗ gắn
          # prefix vào sway/window, nên script tự ghép "[S] tiêu đề".
          if state != "none":
              prefix, klass, hint = "[S]", "s", "scratchpad — $mod+minus ẩn/hiện"
          elif in_floating:
              prefix, klass, hint = "[F]", "f", "popup floating — $mod+Shift+minus cất"
          else:
              prefix, klass, hint = "", "tiled", ""
          text = f"{prefix} {title}".strip() if prefix else title
          print(json.dumps({
              "text": text,
              "class": klass,
              "tooltip": f"{hint} · {title}".strip(" ·") if title else hint,
          }, ensure_ascii=False))


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
