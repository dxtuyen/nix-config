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
      @import url("colors.css");  /* palette wallust theo wallpaper (cùng thư mục, phải đứng đầu) */
      * { font-family: "JetBrains Mono", "Font Awesome 6 Free", monospace; font-size: 13px; border: none; border-radius: 0; }
      @keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.2; } 100% { opacity: 1; } }

      /* Fallback: Tokyo Night — dùng khi colors.css chưa được wallust sinh ra
         (trước lần chạy wallpaper-set đầu tiên). Sau đó @import ở trên đè. */
      :root {
        --wbg: #1a1b26; --wbg2: #24283b; --wfg: #c0caf5; --wtxt2: #a9b1d6;
        --wdim: #414868; --wac: #7aa2f7; --wred: #f7768e; --wgrn: #9ece6a;
        --wylw: #e0af68;
      }

      window#waybar { background: rgba(0, 0, 0, 0); color: var(--wfg); }
      #workspaces { background: var(--wbg2); border: 1px solid var(--wdim); border-radius: 10px; margin: 4px 0 4px 4px; padding: 0 10px; }
      #workspaces button { padding: 0 7px; color: var(--wtxt2); font-size: 15px; border-bottom: 2px solid transparent;
        background-color: rgba(0, 0, 0, 0); }
      #workspaces button:hover, #workspaces button:active {
        background-color: rgba(0, 0, 0, 0); box-shadow: none; }
      #workspaces button.focused, #workspaces button.active { color: var(--wac); border-bottom: 2px solid var(--wac); }
      #workspaces button.urgent { color: var(--wred); border-bottom-color: var(--wred); }
      #workspaces button.persistent.empty { color: var(--wdim); }  /* đậm hơn fallback cũ 1 nấc — chết hẳn bug nháy #3865 */
      #window { background: var(--wbg2); border: 1px solid var(--wac); border-radius: 10px; padding: 0 10px; margin: 4px 0 4px 5px; color: var(--wfg); font-weight: bold; }
      #custom-inhibit, #pulseaudio, #backlight, #temperature, #battery, #power-profiles-daemon, #cpu, #memory, #tray, #mode, #scratchpad { background: var(--wbg2); border: 1px solid var(--wdim); border-radius: 10px; padding: 0 10px; margin: 4px 0; }
      #mode { color: var(--wac); background: var(--wbg2); border: 1px solid var(--wdim); border-radius: 10px; padding: 0 10px; margin: 4px 5px; }
      #scratchpad { color: var(--wtxt2); margin: 4px 5px; }
      #clock { color: var(--wac); font-weight: bold; background: var(--wbg2); border: 1px solid var(--wdim); border-radius: 10px; padding: 0 10px; margin: 4px 10px 4px 5px; }
      #custom-study { background: var(--wbg2); border: 1px solid var(--wdim); border-radius: 10px; padding: 0 10px; margin: 4px 5px; font-weight: bold; }
      #custom-study.running { color: var(--wac); }
      #custom-study.paused { color: var(--wylw); }
      #custom-study.idle { color: var(--wdim); }
      #custom-inhibit.running { color: var(--wac); }
      #custom-inhibit.manual { color: var(--wylw); }
      #custom-inhibit.idle { color: var(--wdim); }
      #battery.warning, #temperature.warning, #cpu.warning, #memory.warning { color: var(--wylw); }
      #battery.critical { color: var(--wred); }
      #temperature.critical, #cpu.critical, #memory.critical { color: var(--wred); animation: blink 1s linear infinite; }
      #battery.charging { color: var(--wgrn); font-weight: bold; }
      #battery.plugged { color: var(--wgrn); }
      #pulseaudio.muted { color: var(--wdim); }
    '';
  };
}
