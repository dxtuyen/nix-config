{ pkgs, ... }:

let
  batteryThreshold = pkgs.writeShellApplication {
    name = "set-battery-threshold";
    text = ''
      start_threshold=80
      end_threshold=85
      configured=0
      for battery in /sys/class/power_supply/BAT*; do
        [ -d "$battery" ] || continue
        if [ -e "$battery/charge_control_start_threshold" ]; then
          start_file="$battery/charge_control_start_threshold"
        elif [ -e "$battery/charge_start_threshold" ]; then
          start_file="$battery/charge_start_threshold"
        else continue; fi
        if [ -e "$battery/charge_control_end_threshold" ]; then
          end_file="$battery/charge_control_end_threshold"
        elif [ -e "$battery/charge_stop_threshold" ]; then
          end_file="$battery/charge_stop_threshold"
        else continue; fi
        printf '%s\n' "$start_threshold" > "$start_file"
        printf '%s\n' "$end_threshold" > "$end_file"
        configured=1
      done
      [ "$configured" -eq 1 ] || echo "Battery does not expose charge thresholds."
    '';
  };
in {
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = { capslock = "overload(control, esc)"; tab = "overload(nav, tab)"; };
        nav = { h = "left"; j = "down"; k = "up"; l = "right"; b = "pageup"; f = "pagedown"; };
      };
    };
  };

  systemd.services.battery-threshold = {
    description = "Set battery charge threshold to 80-85 percent";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; ExecStart = "${batteryThreshold}/bin/set-battery-threshold"; };
  };
}
