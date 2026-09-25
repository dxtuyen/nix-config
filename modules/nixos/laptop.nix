{ lib, pkgs, ... }:

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
  # Swap nén trong RAM (zstd): nhanh hơn swap SSD, đỡ mòn ổ.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Hibernate: swap khai trong hardware-configuration.nix (file tự sinh).
  # Điều kiện: swap ≥ RAM. Sang máy mới sửa UUID resume cho khớp swap mới
  # (docs/03 Bước 7). deep sleep tiết kiệm pin hơn s2idle.
  boot.kernelParams = [
    "resume=UUID=044520bf-eed9-498c-a382-97615c111b1f"
    "mem_sleep_default=deep"
  ];

  services.fwupd.enable = true;
  # Giữ cập nhật firmware nhưng không để daemon chặn greetd lúc đăng nhập.
  systemd.services.fwupd.before = lib.mkForce [ "shutdown.target" ];

  # Đóng nắp → suspend; gắn dock → giữ nguyên. Màn hình luôn khóa khi dậy
  # nhờ before-sleep của swayidle.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

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
