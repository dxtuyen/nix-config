{ ... }:

{
  home.file = {
    ".local/bin/quick-net-reload" = {
      executable = true;
      text = ''
          #! /usr/bin/env bash
          # Reload mạng nhanh: tắt/bật NetworkManager (renew DHCP + DNS).
          # Không cần sudo (polkit cho user local). Dùng khi mạng "đứng hình".
          set -u

          notify() {
            notify-send -a quick-net-reload -i network-wireless -t 3000 "Reload mạng" "$@"
          }

          # Xoá cache DNS (best-effort).
          resolvectl flush-caches >/dev/null 2>&1 || true

          if ! nmcli networking off; then
            notify -u critical "Không tắt được mạng — kiểm tra quyền user/polkit."
            exit 1
          fi
          if ! nmcli networking on; then
            notify -u critical "Không bật lại được mạng — kiểm tra quyền user/polkit."
            exit 1
          fi

          # Chờ kết nối trở lại (tối đa ~10s).
          state=""
          for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
            state="$(nmcli -t -f STATE,CONNECTIVITY general status 2>/dev/null | cut -d: -f2)"
            [ "$state" = "full" ] && break
            sleep 0.5
          done

          if [ "$state" = "full" ]; then
            notify "Đã bật lại mạng — kết nối full."
          else
            notify -u critical "Đã bật lại mạng nhưng chưa kết nối được — kiểm tra wifi."
            exit 1
          fi
      '';
    };
  };
}
