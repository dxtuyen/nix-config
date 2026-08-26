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
        "custom/pomodoro"
        "clock"
      ];
      "modules-right" = [
        "idle_inhibitor"
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
        # Ghim sẵn workspace theo danh sách home/workspaces.nix:
        # luôn hiện trên bar kể cả khi trống.
        # LƯU Ý: key phải là "persistent-workspaces" (gạch nối) —
        # viết gạch dưới thì Waybar bỏ qua im lặng!
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
      "idle_inhibitor" = {
        format = "{icon}";
        "format-icons" = {
          activated = "";
          deactivated = "";
        };
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
        # Font Awesome: moon -> adjust -> sun (thong nhat voi cac module khac)
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
      "custom/pomodoro" = {
        exec = "~/.local/bin/pomodoro status";
        signal = 8;
        return-type = "json";
        "on-click" = "~/.local/bin/pomodoro-menu";
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
      window#waybar { background: rgba(0, 0, 0, 0); color: #c0caf5; }
      #workspaces { background: #24283b; border: 1px solid #414868; border-radius: 10px; margin: 4px 0 4px 4px; padding: 0 10px; }
      #workspaces button { padding: 0 7px; color: #a9b1d6; font-size: 15px; border-bottom: 2px solid transparent;
        background-color: rgba(0, 0, 0, 0); }
      #workspaces button:hover, #workspaces button:active {
        background-color: rgba(0, 0, 0, 0); box-shadow: none; }
      #workspaces button.focused, #workspaces button.active { color: #7aa2f7; border-bottom: 2px solid #7aa2f7; }
      #workspaces button.urgent { color: #f7768e; border-bottom-color: #f7768e; }
      #workspaces button.persistent.empty { color: #737aa2; }  /* TN dark5 — sát tone #a9b1d6 để bug nháy #3865 gần như vô hình */
      #window { background: #364a82; border: 1px solid #7aa2f7; border-radius: 10px; padding: 0 10px; margin: 4px 0 4px 5px; color: #c0caf5; font-weight: bold; }
      #idle_inhibitor, #pulseaudio, #backlight, #temperature, #battery, #power-profiles-daemon, #cpu, #memory, #tray, #mode, #scratchpad { background: #24283b; border: 1px solid #414868; border-radius: 10px; padding: 0 10px; margin: 4px 0; }
      #mode { color: #7aa2f7; background: #24283b; border: 1px solid #414868; border-radius: 10px; padding: 0 10px; margin: 4px 5px; }
      #scratchpad { color: #a9b1d6; margin: 4px 5px; }
      #clock { color: #7aa2f7; font-weight: bold; background: #24283b; border: 1px solid #414868; border-radius: 10px; padding: 0 10px; margin: 4px 10px 4px 5px; }
      #custom-pomodoro { background: #24283b; border: 1px solid #414868; border-radius: 10px; padding: 0 10px; margin: 4px 5px; font-weight: bold; }
      #custom-pomodoro.running { color: #f7768e; }
      #custom-pomodoro.idle { color: #565f89; }
      #custom-pomodoro.break { color: #9ece6a; }
      #custom-pomodoro.custom { color: #7aa2f7; }
      #battery.warning, #temperature.warning, #cpu.warning, #memory.warning { color: #e0af68; }
      #battery.critical { color: #f7768e; }
      #temperature.critical, #cpu.critical, #memory.critical { color: #f7768e; animation: blink 1s linear infinite; }
      #battery.charging { color: #9ece6a; font-weight: bold; }
      #battery.plugged { color: #9ece6a; }
      #pulseaudio.muted { color: #565f89; }
    '';
  };
}
