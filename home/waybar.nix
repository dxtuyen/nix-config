{ config, ... }:

let
  # Danh sách tên workspace dùng chung ở home/workspaces.nix
  ws = import ./workspaces.nix;
in

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      position = "top";
      height = 30;
      spacing = 4;
      "modules-left" = [
        "sway/workspaces"
        "sway/window"
        "sway/mode"
        "sway/scratchpad"
      ];
      "modules-center" = [
        "custom/study"
        "clock"
      ];
      "modules-right" = [
        "custom/inhibit"
        "power-profiles-daemon"
        "pulseaudio"
        "backlight"
        "temperature"
        "battery"
        "cpu"
        "memory"
        "tray"
      ];
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
      pulseaudio = {
        format = "{volume}% {icon}";
        "format-muted" = "muted";
        "format-icons".default = [
          ""
          ""
          ""
        ];
        "on-click" = "pavucontrol";
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
        "warning-threshold" = 65;
        "critical-threshold" = 80;
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
        format = "{:%a %d %b | %I:%M %p}";
        "format-alt" = "{:%A %d %B %Y}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        locale = "en_US.UTF-8";
      };
      tray = {
        spacing = 10;
        "icon-size" = 16;
      };
    };
    style = ''
      * { font-family: "JetBrains Mono", "Font Awesome 6 Free", monospace; font-size: 13px; border: none; border-radius: 0; }
      @keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.2; } 100% { opacity: 1; } }
      window#waybar { background: rgba(0, 0, 0, 0); color: #cdd6f4; }
      #workspaces { background: #181825; border: 1px solid #45475a; border-radius: 10px; margin: 4px 0 4px 4px; padding: 0 10px; }
      #workspaces button { padding: 0 7px; color: #bac2de; font-size: 15px; border-bottom: 2px solid transparent;
        background-color: rgba(0, 0, 0, 0); }
      #workspaces button:hover, #workspaces button:active {
        background-color: rgba(0, 0, 0, 0); box-shadow: none; }
      #workspaces button.focused, #workspaces button.active { color: #89b4fa; border-bottom: 2px solid #89b4fa; }
      #workspaces button.urgent { color: #f38ba8; border-bottom-color: #f38ba8; }
      #workspaces button.persistent.empty { color: #7f849c; }  /* overlay1 — sát tone subtext để bug nháy gần như vô hình */
      #window { background: #313244; border: 1px solid #89b4fa; border-radius: 10px; padding: 0 10px; margin: 4px 0 4px 5px; color: #cdd6f4; font-weight: bold; }
      #custom-inhibit, #pulseaudio, #backlight, #temperature, #battery, #power-profiles-daemon, #cpu, #memory, #tray, #mode, #scratchpad { background: #181825; border: 1px solid #45475a; border-radius: 10px; padding: 0 10px; margin: 4px 0; }
      #mode { color: #89b4fa; background: #181825; border: 1px solid #45475a; border-radius: 10px; padding: 0 10px; margin: 4px 5px; }
      #scratchpad { color: #bac2de; margin: 4px 5px; }
      #clock { color: #89b4fa; font-weight: bold; background: #181825; border: 1px solid #45475a; border-radius: 10px; padding: 0 10px; margin: 4px 10px 4px 5px; }
      #custom-study { background: #181825; border: 1px solid #45475a; border-radius: 10px; padding: 0 10px; margin: 4px 5px; font-weight: bold; }
      #custom-study.running { color: #89b4fa; }
      #custom-study.paused { color: #fab387; }
      #custom-study.idle { color: #6c7086; }
      #custom-inhibit.running { color: #89b4fa; }
      #custom-inhibit.manual { color: #fab387; }
      #custom-inhibit.idle { color: #6c7086; }
      #battery.warning, #temperature.warning, #cpu.warning, #memory.warning { color: #fab387; }
      #battery.critical { color: #f38ba8; }
      #temperature.critical, #cpu.critical, #memory.critical { color: #f38ba8; animation: blink 1s linear infinite; }
      #battery.charging { color: #a6e3a1; font-weight: bold; }
      #battery.plugged { color: #a6e3a1; }
      #pulseaudio.muted { color: #6c7086; }
    '';
  };
}
