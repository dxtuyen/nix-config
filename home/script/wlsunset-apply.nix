{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wlsunset-apply" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # wlsunset-apply [warm|white|natural] — khởi động wlsunset với mode đã chọn.
        #   có đối số  → dùng mode đó và GHI vào state (lựa chọn của user)
        #   không có    → đọc state đã lưu; thiếu / sai giá trị → natural
        # State: ~/.local/state/wlsunset-mode — sống qua tắt/mở máy, nên menu
        # Display (☀ → warm/cool/natural) không bị reset về Natural mỗi lần
        # đăng nhập. Args định nghĩa DUY NHẤT ở đây; sway.nix, refresh-session
        # và wlsunset-menu chỉ gọi script này.
        set -u

        STATE="$HOME/.local/state/wlsunset-mode"
        requested="''${1:-}"
        mode=""

        if [ -n "$requested" ]; then
          mode="$requested"
        elif [ -r "$STATE" ]; then
          IFS= read -r mode < "$STATE" || true
        fi

        case "$mode" in
          warm)    args="-t 3900 -T 4000" ;;
          white)   args="-t 6400 -T 6500" ;;
          natural) args="-t 4000 -T 6500" ;;
          *)       mode="natural"; args="-t 4000 -T 6500" ;;
        esac

        # Chỉ ghi state khi user chọn tường minh — state = lựa chọn cuối cùng.
        # Gọi không đối số (lúc login / refresh) chỉ đọc, không đè.
        if [ -n "$requested" ]; then
          mkdir -p "''${STATE%/*}"
          printf '%s\n' "$mode" > "$STATE"
        fi

        pkill -x wlsunset 2>/dev/null || true
        for _ in {1..20}; do
          pgrep -x wlsunset >/dev/null || break
          sleep 0.05
        done
        # shellcheck disable=SC2086
        ${pkgs.wlsunset}/bin/wlsunset $args -l 21.0 -L 105.8 >/dev/null 2>&1 &
      '';
    };
  };
}
