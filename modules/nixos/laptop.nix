{ pkgs, ... }:

let
  batteryThreshold = pkgs.writeShellApplication {
    name = "set-battery-threshold";
    text = ''
      start_threshold=85
      end_threshold=90
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
in
{
  # zram — compressed swap inside RAM (zstd). Much faster than SSD swap and
  # reduces SSD wear. Ubuntu/Fedora/ChromeOS enable it by default.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # 50% RAM as compressed swap (Fedora default)
    priority = 100; # higher priority than any disk swap
  };

  # Tuning for a zram-only system: let the kernel swap to zram eagerly instead
  # of waiting too long and letting OOM-killer eat desktop apps under load.
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 10;
    "vm.page-cluster" = 0; # reduce latency for single-page swaps on RAM
  };

  services.fwupd.enable = true;

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(control, esc)";
          tab = "overload(nav, tab)";
        };
        nav = {
          h = "left";
          j = "down";
          k = "up";
          l = "right";
          u = "home";
          i = "end";
          o = "pageup";
          p = "pagedown";
        };
      };
    };
  };

  systemd.services.battery-threshold = {
    description = "Set battery charge threshold to 85-90 percent";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${batteryThreshold}/bin/set-battery-threshold";
    };
  };
}
