{ ... }:

{
  home.file = {
    ".local/bin/quick-net-reload" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Fast network reload: toggle NetworkManager (renew DHCP + DNS).
        # No sudo needed (polkit allows local users). Use when the network "hangs".
        set -u

        notify() {
          notify-send -a quick-net-reload -i network-wireless -t 3000 "Network reload" "$@"
        }

        # Flush DNS cache (best-effort).
        resolvectl flush-caches >/dev/null 2>&1 || true

        if ! nmcli networking off; then
          notify -u critical "Could not turn networking off — check user/polkit permissions."
          exit 1
        fi
        if ! nmcli networking on; then
          notify -u critical "Could not turn networking back on — check user/polkit permissions."
          exit 1
        fi

        # Wait for the connection to come back (up to ~10s).
        state=""
        for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
          state="$(nmcli -t -f STATE,CONNECTIVITY general status 2>/dev/null | cut -d: -f2)"
          [ "$state" = "full" ] && break
          sleep 0.5
        done

        if [ "$state" = "full" ]; then
          notify "Networking back on — full connectivity."
        else
          notify -u critical "Networking is back but not connected yet — check wifi."
          exit 1
        fi
      '';
    };
  };
}
