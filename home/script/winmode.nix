{ pkgs, ... }:

# Winmode: huy hiệu LOẠI cửa sổ đang focus trên Waybar — [S] = scratchpad,
# [F] = popup floating, rỗng = tiled (module ẩn). Là pill NHỎ RIÊNG đứng NGAY
# SAU tiêu đề (module `sway/window` gốc giữ nguyên, không viết lại title). Lý
# do tồn tại: 2 loại floating trông giống hệt nhau nhưng phím thao tác KHÁC
# nhau ($mod+minus chỉ toggle scratchpad).
#
# Tối ưu độ trễ để huy hiệu khớp tiêu đề gần như tức thì (bản cũ ~90ms):
#   - `status` (Waybar spawn mỗi lần cập nhật): shell + jq (~7ms) thay vì
#     python3 (~62ms).
#   - `watch` (daemon): gửi signal bằng builtin `kill` thay vì `pkill` quét
#     /proc (~23ms mỗi sự kiện).
{
  home.file.".local/bin/winmode" = {
    executable = true;
    text = ''
      #!/bin/sh
      # winmode status|watch — huy hiệu loại cửa sổ focus cho Waybar (signal 9).
      #   status: in JSON {"text": "[S]|[F]|<rỗng>", "class": ..., "tooltip": ...}
      #   watch : nghe sự kiện window của Sway → gửi SIGRTMIN+9 cho Waybar.
      # Dùng đường dẫn store tuyệt đối (swaymsg/jq) → không phụ thuộc PATH.
      SWAYMSG=${pkgs.sway}/bin/swaymsg
      JQ=${pkgs.jq}/bin/jq

      status() {
        tree=$("$SWAYMSG" -t get_tree 2>/dev/null) || tree=""
        if [ -z "$tree" ]; then
          # Không có Sway / IPC lỗi → text rỗng, module tự ẩn (hide-empty-text).
          printf '%s\n' '{"text":"","class":"tiled","tooltip":""}'
          return 0
        fi
        printf '%s' "$tree" | "$JQ" -c '
          [ paths as $p | getpath($p) | objects | select(.focused == true)
          | { title: ((.name // "") | gsub("\\n"; " ") | sub("^ +"; "") | sub(" +$"; "")),
              scratchpad: (.scratchpad_state // "none"),
              floating: ($p | index("floating_nodes") != null) } ]
          | first as $w
          | if $w == null then {text:"",class:"tiled",tooltip:""}
            elif $w.scratchpad != "none" then
              {text:"[S]", class:"s",
               tooltip:("scratchpad — $mod+minus ẩn/hiện"
                        + (if $w.title != "" then " · " + $w.title else "" end))}
            elif $w.floating then
              {text:"[F]", class:"f",
               tooltip:("popup floating — $mod+Shift+minus cất"
                        + (if $w.title != "" then " · " + $w.title else "" end))}
            else {text:"",class:"tiled",tooltip:""}
            end'
      }

      watch() {
        # PID Waybar: dò một lần; dò lại khi kill thất bại (Waybar restart).
        pid=$(pgrep -x waybar 2>/dev/null | head -n1)
        # swaymsg thoát (Sway chết) → vòng lặp dừng → systemd Restart=always
        # hồi sinh; sway-session.target dừng thì service dừng theo (PartOf).
        "$SWAYMSG" -m -t subscribe '["window"]' | while read -r _line; do
          # Mọi sự kiện window (focus/move/close) đều có thể đổi trạng thái;
          # gửi signal rẻ hơn nhiều so với tự phân tích JSON từng dòng.
          if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
            pid=$(pgrep -x waybar 2>/dev/null | head -n1)
          fi
          [ -n "$pid" ] && kill -s RTMIN+9 "$pid" 2>/dev/null
        done
      }

      case "''${1:-}" in
        status) status ;;
        watch) watch ;;
        *) printf '%s\n' 'usage: winmode status|watch' >&2; exit 2 ;;
      esac
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
      # PATH chỉ cần cho `pgrep` (swaymsg/jq dùng đường dẫn store tuyệt đối).
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
