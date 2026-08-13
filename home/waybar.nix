{ ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.mainBar = {
      position = "bottom";
      height = 30;
      spacing = 4;
      "modules-left" = [
        "sway/workspaces"
        "sway/mode"
        "sway/scratchpad"
      ];
      "modules-center" = [ "sway/window" ];
      "modules-right" = [
        "idle_inhibitor"
        "pulseaudio"
        "network"
        "power-profiles-daemon"
        "cpu"
        "memory"
        "temperature"
        "backlight"
        "battery"
        "clock"
        "tray"
      ];
      "sway/workspaces" = {
        "disable-scroll" = true;
        "warp-on-scroll" = false;
        format = "{name}";
      };
      "sway/window" = {
        format = "{}";
        "max-length" = 80;
      };
      "sway/scratchpad" = {
        format = "{icon} {count}";
        "show-empty" = false;
        "format-icons" = [ "" "" ];
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
      network = {
        "format-wifi" = "{essid} ({signalStrength}%) ";
        "format-ethernet" = "{ipaddr}/{cidr} ";
        "format-disconnected" = "Disconnected ⚠";
      };
      "power-profiles-daemon" = {
        format = "{icon}";
        "format-icons" = {
          performance = "";
          balanced = "";
          "power-saver" = "";
        };
      };
      cpu = {
        format = " {usage}%";
      };
      memory = {
        format = " {}%";
      };
      temperature = {
        "warning-threshold" = 65;
        "critical-threshold" = 80;
        format = " {temperatureC}°C";
      };
      backlight = {
        format = "{icon} {percent}%";
        "format-icons" = [
          "🌑"
          "🌘"
          "🌗"
          "🌖"
          "🌕"
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
      clock = {
        format = " {:%H:%M}";
        "format-alt" = "{:%Y-%m-%d}";
      };
      tray.spacing = 10;
    };
    style = ''
      * { font-family: "JetBrains Mono", "Font Awesome 6 Free", monospace; font-size: 13px; border: none; border-radius: 0; }
      window#waybar { background: rgba(10, 14, 23, .92); color: #4af626; border-top: 1px solid rgba(74,246,38,.22); }
      #workspaces button { padding: 0 7px; color: #718079; font-size: 15px; }
      #workspaces button.focused, #workspaces button.active { color: #4af626; font-weight: bold; border-bottom: 2px solid #4af626; }
      #clock { color: #4af626; font-weight: bold; }
      #window { margin: 0 5px; color: #a8d9a0; }
      #scratchpad { margin: 0 5px; padding-left: 10px; color: #a8d9a0; border-left: 1px solid rgba(74,246,38,.22); }
      #idle_inhibitor, #pulseaudio, #network, #power-profiles-daemon, #cpu, #memory, #temperature, #backlight, #battery, #tray { padding: 0 10px; color: #a8d9a0; border-left: 1px solid rgba(74,246,38,.22); }
      #battery.warning, #temperature.warning { color: #f5b84b; }
      #battery.critical, #temperature.critical { color: #ff5555; }
      #battery.charging { color: #00aaff; background-color: rgba(0, 102, 204, 0.35); font-weight: bold; }
      #battery.plugged { color: #00aaff; }
      #network.disconnected, #pulseaudio.muted { color: #718079; }
    '';
  };
}