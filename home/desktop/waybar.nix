{ config, ... }:

let
  # Use Font Awesome for consistent icon sizing and alignment.
  faSpan = s: "<span font_family='Font Awesome 7 Free'>${s}</span>";
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
        # Focused window title.
        "sway/window"
        "sway/mode"
        "custom/away-windows"
      ];
      "modules-center" = [
        "custom/study"
        "clock"
      ];
      "modules-right" = [
        "custom/inhibit"
        "group/devices"
        "group/hardware"
        "group/power"
        "tray"
      ];
      "group/devices" = {
        orientation = "horizontal";
        modules = [
          "bluetooth"
          "network"
          "pulseaudio"
          "backlight"
        ];
      };
      "group/hardware" = {
        orientation = "horizontal";
        modules = [
          "cpu"
          "memory"
        ];
      };
      "group/power" = {
        orientation = "horizontal";
        modules = [
          "power-profiles-daemon"
          "battery"
        ];
      };
      network = {
        interval = 5;
        "on-click" = "foot --app-id=wifitui -T 'Wi-Fi' wifitui";
        format-wifi = "${faSpan ""} {signalStrength}%";
        format-ethernet = "${faSpan ""} LAN";
        format-disconnected = faSpan "";
        format-disabled = faSpan "";
        tooltip-format-wifi = "SSID: {essid}\nSignal: {signalStrength}%\n↓ {bandwidthDownBits}  ↑ {bandwidthUpBits}\nIP: {ipaddr}/{cidr}\nGateway: {gwaddr}";
        tooltip-format-ethernet = "Interface: {ifname}\n↓ {bandwidthDownBits}  ↑ {bandwidthUpBits}\nIP: {ipaddr}/{cidr}\nGateway: {gwaddr}";
        tooltip-format-disconnected = "Network disconnected";
        tooltip-format-disabled = "Wi-Fi disabled";
      };
      bluetooth = {
        # Keep the status label after the icon as plain text.
        # Show connected-device details in the tooltip.
        format = faSpan "";
        "format-disabled" = "${faSpan ""} Disabled";
        "format-off" = "${faSpan ""} Off";
        "format-on" = "${faSpan ""} On";
        "format-connected" = faSpan "";
        "format-no-controller" = "${faSpan ""} N/A";
        tooltip = true;
        "tooltip-format" = "{controller_alias}: {status}";
        "tooltip-format-connected" = "{controller_alias} · {num_connections} connected\n{device_enumerate}";
        "tooltip-format-enumerate-connected" = "{device_alias}";
        "on-click" = "foot --app-id=bluetui -T Bluetooth bluetui";
      };
      # Keep all five workspaces visible.
      "sway/workspaces" = {
        "disable-scroll" = true;
        "persistent-workspaces" = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
      };
      "sway/window" = {
        format = "{title}";
        "max-length" = 60;
        tooltip = true;
        # Click the title to open the window menu.
        "on-click" = "~/.local/bin/window-menu";
      };

      # Reuse the Mod+= list for both the label and tooltip.
      "custom/away-windows" = {
        "exec" = "~/.local/bin/window-menu --away --waybar";
        "return-type" = "json";
        "interval" = "once";
        # The Sway event listener refreshes this module immediately.
        "signal" = 9;
        "format" = "${faSpan ""} {text}";
        "max-length" = 42;
        "hide-empty-text" = true;
        "escape" = true;
        "on-click" = "~/.local/bin/window-menu --away";
      };
      pulseaudio = {
        format = "{volume}% ${faSpan "{icon}"}";
        "format-muted" = "muted";
        "format-icons".default = [
          ""
          ""
          ""
        ];
        "on-click" = "foot --app-id=wiremix -T 'Audio' wiremix";
      };
      "power-profiles-daemon" = {
        # Show the profile name in the tooltip.
        format = faSpan "{icon}";
        tooltip = true;
        "tooltip-format" = "{profile}";
        "on-click" = "~/.local/bin/power-profile-menu";
        "format-icons" = {
          performance = "";
          balanced = "";
          "power-saver" = "";
        };
      };
      cpu = {
        format = "${faSpan ""} {usage}%";
        states = {
          warning = 70;
          critical = 90;
        };
      };
      memory = {
        format = "${faSpan ""} {}%";
        states = {
          warning = 80;
          critical = 95;
        };
      };
      backlight = {
        format = "${faSpan "{icon}"} {percent}%";
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
        format = "${faSpan "{icon}"} {capacity}%";
        "format-charging" = "${faSpan ""} {capacity}%";
        "format-plugged" = "${faSpan ""} {capacity}%";
        "format-icons" = [
          ""
          ""
          ""
          ""
          ""
        ];
      };
      # Countdown status and controls.
      "custom/study" = {
        exec = "~/.local/bin/countdown-engine status";
        signal = 8;
        return-type = "json";
        "on-click" = "~/.local/bin/countdown";
      };
      # Idle-inhibition status.
      "custom/inhibit" = {
        exec = "~/.local/bin/countdown-engine inhibit";
        # Escape markup in the tooltip.
        format = faSpan "{text}";
        escape = true;
        signal = 7;
        return-type = "json";
        "on-click" = "~/.local/bin/countdown-engine inhibit-toggle";
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
      /* Use JetBrains Mono for text; icons specify their own font. */
      * { font-family: "JetBrains Mono", "JetBrains Mono Nerd Font Mono", monospace; font-size: 13px; border: none; border-radius: 0; }

      /* Catppuccin colors for pills, text, and accents. */
      @define-color pill rgba(30, 30, 46, 0.80);   /* Catppuccin base */
      @define-color pill-hover rgba(49, 50, 68, 1); /* Catppuccin surface0 */
      @define-color edge rgba(69, 71, 90, 0.45);    /* Catppuccin surface1 */
      @define-color txt #bac2de;                    /* Catppuccin subtext1 */
      @define-color txt-strong #cdd6f4;             /* Catppuccin text */
      @define-color muted #7f849c;                   /* Catppuccin overlay1 */

      @keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.2; } 100% { opacity: 1; } }
      window#waybar { background: rgba(0, 0, 0, 0); color: @txt; }
      #workspaces { background: @pill; border: 1px solid @edge; border-radius: 10px; margin: 4px 0 4px 4px; padding: 0 10px; }
      #workspaces button { padding: 0 7px; color: @txt; font-size: 15px; border-bottom: 2px solid transparent;
        background-color: rgba(0, 0, 0, 0); }
      #workspaces button:hover, #workspaces button:active {
        background-color: rgba(0, 0, 0, 0); box-shadow: none; }
      #workspaces button.focused, #workspaces button.active {
        color: @txt-strong;
        background-color: rgba(137, 180, 250, 0.16);
        border-radius: 6px;
      }
      #workspaces button.urgent { color: #f38ba8; border-bottom-color: #f38ba8; }
      /* Dim empty workspaces. */
      #workspaces button.persistent.empty { color: #6c7086; }
      /* Keep the focused empty workspace highlighted. */
      #workspaces button.persistent.empty.focused { background-color: rgba(137, 180, 250, 0.16); }
      #window { background: @pill-hover; border: 1px solid rgba(137, 180, 250, 0.5); border-radius: 10px; padding: 0 10px; margin: 4px 0 4px 5px; color: @txt-strong; font-weight: bold; }
      #custom-inhibit, #tray, #mode, #custom-away-windows,
      box#devices, box#hardware, box#power {
        background: @pill;
        border: 1px solid @edge;
        border-radius: 10px;
        padding: 0 4px;
        margin: 4px 2px;
      }
      box#devices > widget > *,
      box#hardware > widget > *,
      box#power > widget > * {
        padding: 0 6px;
        margin: 0;
        border: none;
        background: transparent;
      }
      #tray { padding: 0 8px; margin: 4px 4px 4px 2px; }
      #mode { color: #89b4fa; background: @pill; border: 1px solid rgba(137, 180, 250, 0.5); border-radius: 10px; padding: 0 10px; margin: 4px 5px; }
      #clock { color: @txt; font-weight: bold; background: @pill; border: 1px solid @edge; border-radius: 10px; padding: 0 10px; margin: 4px 10px 4px 5px; }
      #custom-study { background: @pill; border: 1px solid @edge; border-radius: 10px; padding: 0 10px; margin: 4px 5px; font-weight: bold; }
      #custom-study.running { color: #89b4fa; }
      #custom-study.paused { color: #fab387; }
      #custom-study.idle { color: @muted; }
      #custom-inhibit.running { color: #89b4fa; }
      /* Add vertical padding to the icon-only pill. */
      #custom-inhibit { padding: 2px 10px; margin: 4px 4px 4px 2px; }
      #power-profiles-daemon { padding: 0 4px; }
      #bluetooth.off, #bluetooth.disabled, #bluetooth.no-controller { color: @muted; }
      #bluetooth.connected { color: #a6e3a1; }
      #custom-inhibit.manual { color: #fab387; }
      #custom-inhibit.idle { color: @muted; }
      #network.disconnected, #network.disabled { color: #f38ba8; }
      #battery.warning, #cpu.warning, #memory.warning { color: #fab387; }
      #battery.critical { color: #f38ba8; }
      #cpu.critical, #memory.critical { color: #f38ba8; animation: blink 1s linear infinite; }
      #battery.charging { color: #a6e3a1; font-weight: bold; }
      #battery.plugged { color: #a6e3a1; }
      #pulseaudio.muted { color: @muted; }
    '';
  };
}
