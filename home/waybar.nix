{ ... }:

let
  # Danh sách tên workspace dùng chung ở home/workspaces.nix
  ws = import ./workspaces.nix;
in

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    # CSS riêng: style nhận path → dùng file mới.
    style = ./waybar-style.css;
    settings.mainBar = {
      position = "top";
      height = 30;
      spacing = 2;
      # ── Left pill ──────────────────────────
      "modules-left" = [
        "group/ws-left"
      ];
      # ── Center pill ───────────────────────
      "modules-center" = [
        "group/ws-center"
      ];
      # ── Right pills ────────────────────────
      "modules-right" = [
        "group/ws-status"
        "group/ws-resources"
        "tray"
      ];

      # ═══════════════════════════════════════════
      #  LEFT pill: workspaces + window + mode + scratchpad
      # ═══════════════════════════════════════════
      "group/ws-left" = {
        orientation = "horizontal";
        "show-constant" = true;
        "modules" = [
          "sway/workspaces"
          "sway/window"
          "sway/mode"
          "sway/scratchpad"
        ];
      };

      # ═══════════════════════════════════════════
      #  CENTER pill: pomodoro + clock
      # ═══════════════════════════════════════════
      "group/ws-center" = {
        orientation = "horizontal";
        "show-constant" = true;
        "modules" = [
          "custom/study"
          "clock"
        ];
      };

      # ═══════════════════════════════════════════
      #  RIGHT pill 1: status icons (icon-only)
      # ═══════════════════════════════════════════
      "group/ws-status" = {
        orientation = "horizontal";
        "show-constant" = true;
        "modules" = [
          "custom/inhibit"
          "power-profiles-daemon"
          "network"
          "wireplumber"
          "backlight"
        ];
      };

      # ═══════════════════════════════════════════
      #  RIGHT pill 2: resources (icon + %)
      # ═══════════════════════════════════════════
      "group/ws-resources" = {
        orientation = "horizontal";
        "show-constant" = true;
        "modules" = [
          "cpu"
          "memory"
          "temperature"
          "battery"
        ];
      };
      "sway/workspaces" = {
        "disable-scroll" = true;
        "warp-on-scroll" = false;
        format = "{name}";
        # Ghim workspace từ workspaces.nix (kể cả khi trống).
        # Key phải có gạch nối (gạch dưới bị Waybar bỏ qua).
        "persistent-workspaces" = builtins.listToAttrs (
          map (name: {
            inherit name;
            value = [ ];
          }) ws
        );
      };
      "sway/window" = {
        format = "{title}";
        "max-length" = 60;
        tooltip = true;
      };
      "sway/scratchpad" = {
        format = "{icon} {count}";
        "show-empty" = false;
        "format-icons" = [
          ""
          ""
        ];
        tooltip = true;
        "tooltip-format" = "{app}: {title}";
      };
      wireplumber = {
        format = "{icon} {volume}%";
        "format-muted" = "󰝟 muted";
        "format-icons" = [
          ""
          ""
          ""
        ];
        "on-click" = "pavucontrol";
        "on-click-right" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "scroll-step" = 2;
        tooltip = true;
      };
      network = {
        "format-wifi" = "";
        "format-ethernet" = "󰈀";
        "format-disconnected" = "󰖪";
        "format-disabled" = "󰖪 off";
        "tooltip-format-wifi" = "{essid} · {signalStrength}% · {ipaddr}";
        "tooltip-format-ethernet" = "{ifname} · {ipaddr}";
        "tooltip-format-disconnected" = "Mất kết nối";
        "on-click" = "nm-connection-editor";
        "interval" = 15;
      };
      "power-profiles-daemon" = {
        format = "{icon} {profile}";
        "format-icons" = {
          performance = "";
          balanced = "";
          "power-saver" = "";
        };
      };
      cpu = {
        format = " {usage}%";
        states = {
          warning = 70;
          critical = 90;
        };
      };
      memory = {
        format = " {}%";
        states = {
          warning = 80;
          critical = 95;
        };
      };
      temperature = {
        # Chỉ đọc CPU Package (coretemp) thay vì sensor mặc định dễ sai trên laptop.
        "hwmon-path-abs" = "/sys/devices/platform/coretemp.0/hwmon";
        "input-filename" = "temp1_input";
        "warning-threshold" = 65;
        "critical-threshold" = 85;
        format = " {temperatureC}°C";
      };
      backlight = {
        format = "{icon} {percent}%";
        "format-icons" = [
          ""
          ""
          ""
        ];
      };
      battery = {
        states = {
          warning = 25;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        "format-charging" = " {capacity}%";
        "format-plugged" = " {capacity}%";
        "tooltip-format" = "{capacity}% · {timeTo}";
        "format-icons" = [
          ""
          ""
          ""
          ""
          ""
        ];
      };
      # Đồng hồ phiên tập trung (xem pomodoro.nix).
      "custom/study" = {
        exec = "~/.local/bin/study status";
        signal = 8;
        return-type = "json";
        "on-click" = "~/.local/bin/pomodoro-menu";
      };
      # Icon mắt: xanh = phiên chạy, vàng = bật tay, mờ = không chống idle.
      "custom/inhibit" = {
        exec = "~/.local/bin/study inhibit";
        signal = 7;
        return-type = "json";
        "on-click" = "~/.local/bin/study inhibit-toggle";
      };
      clock = {
        format = "{:%a %d %b · %H:%M}";
        "format-alt" = "{:%A %d %B %Y}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        locale = "en_US.UTF-8";
      };
      tray = {
        spacing = 10;
        "icon-size" = 16;
      };
    };
  };
}
