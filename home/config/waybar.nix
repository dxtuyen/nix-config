{ config, ... }:

let
  # Danh sách tên workspace dùng chung ở home/config/workspaces.nix
  ws = import ./workspaces.nix;

  # Bọc MỌI glyph icon (codepoint PUA trong `format-icons`) vào "Font Awesome 7
  # Free": advance = ink nên icon vừa vừa ngang chữ, vừa căn giữa, đáy trùng
  # baseline, line-height không tăng. Nerd Font thì hoặc tràn ô, hoặc icon bé.
  # FA7 Free phủ đủ 19/19 codepoint đang dùng (`fc-list ':charset=<cp>' family`).
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
        # Thay sway/window: script ghép "[S]/[F] tiêu đề" trong cùng một pill.
        "custom/winmode"
        "sway/mode"
        "sway/scratchpad"
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
          "temperature"
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
        tooltip-format-wifi = "SSID: {essid}\nSignal: {signalStrength}%\nIP: {ipaddr}/{cidr}\nGateway: {gwaddr}";
        tooltip-format-ethernet = "Interface: {ifname}\nIP: {ipaddr}/{cidr}\nGateway: {gwaddr}";
        tooltip-format-disconnected = "Network disconnected";
        tooltip-format-disabled = "Wi-Fi disabled";
      };
      bluetooth = {
        # Chỉ icon cho gọn — hover để xem chi tiết thiết bị qua tooltip.
        format = faSpan "";
        "format-disabled" = faSpan "";
        "format-off" = faSpan "";
        "format-on" = faSpan "";
        "format-connected" = faSpan "";
        "format-no-controller" = faSpan "";
        tooltip = true;
        "tooltip-format" = "{controller_alias}: {status}";
        "tooltip-format-connected" = "{controller_alias} · {num_connections} connected\n{device_enumerate}";
        "tooltip-format-enumerate-connected" = "{device_alias}";
        "on-click" = "foot --app-id=bluetui -T Bluetooth bluetui";
      };
      "sway/workspaces" = {
        "disable-scroll" = true;
        "warp-on-scroll" = false;
        format = "{name}";
        # Ghim workspace từ workspaces.nix (kể cả khi trống). Key phải có
        # gạch nối (gạch dưới bị Waybar bỏ qua).
        "persistent-workspaces" = builtins.listToAttrs (
          map (name: {
            inherit name;
            value = [ ];
          }) ws
        );
      };
      "sway/scratchpad" = {
        format = "${faSpan "{icon}"} {count}";
        "show-empty" = false;
        "format-icons" = [
          ""
          ""
        ];
        tooltip = true;
        "tooltip-format" = "{app}: {title}";
      };
      pulseaudio = {
        format = "{volume}% ${faSpan "{icon}"}";
        "format-muted" = "muted";
        "format-icons".default = [
          ""
          ""
          ""
        ];
        "on-click" = "pavucontrol";
      };
      "power-profiles-daemon" = {
        # CHỈ icon (bỏ chữ profile) cho gọn — rê chuột vẫn thấy tên qua tooltip.
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
      temperature = {
        "warning-threshold" = 65;
        "critical-threshold" = 80;
        format = "${faSpan ""} {temperatureC}°C";
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
      # Tiêu đề cửa sổ focus (script: home/script/winmode.nix), thay sway/window:
      # tiled = tiêu đề trần · scratchpad/popup = "[S] tiêu đề" / "[F] tiêu đề"
      # (tiền tố đứng trước chữ, cùng một pill). Signal 9, không poll.
      "custom/winmode" = {
        exec = "~/.local/bin/winmode status";
        signal = 9;
        return-type = "json";
        format = "{text}";
        "max-length" = 64;
        tooltip = true;
        "on-click" = "~/.local/bin/scratchpad-menu";
      };
      # Đồng hồ Countdown (engine: home/script/countdown-engine.nix, menu: countdown).
      # Giữ id module `custom/study` để không phải sửa `modules-center` ở trên.
      "custom/study" = {
        exec = "~/.local/bin/countdown-engine status";
        signal = 8;
        return-type = "json";
        "on-click" = "~/.local/bin/countdown";
      };
      # Icon mắt: xanh = phiên chạy, vàng = bật tay, mờ = không chống idle.
      "custom/inhibit" = {
        exec = "~/.local/bin/countdown-engine inhibit";
        # Script in glyph mắt; `escape = true` chỉ escape &<> trong tooltip.
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
      /* Icon đã bọc span "Font Awesome 7 Free" (xem `faSpan`); font ở đây lo chữ. */
      * { font-family: "JetBrains Mono", "JetBrains Mono Nerd Font Mono", monospace; font-size: 13px; border: none; border-radius: 0; }

      /* Màu phân tầng theo vai trò: pill · stat (@txt) · title window bold ·
         accent #89b4fa. GTK CSS không có var() nên dùng @define-color. */
      @define-color pill rgba(30, 30, 46, 0.80);   /* Catppuccin base, 80% opacity */
      @define-color pill-hover rgba(49, 50, 68, 1);  /* surface0 đục hẳn — nền title không trong suốt */
      @define-color edge rgba(69, 71, 90, 0.45);     /* surface1, viền mờ */
      @define-color txt #bac2de;                     /* subtext1 */
      @define-color txt-strong #cdd6f4;              /* text */
      @define-color muted #7f849c;                   /* overlay1 */

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
      #workspaces button.persistent.empty { color: @muted; }
      /* Tiêu đề focus — winmode thay sway/window. tiled/s/f cùng một pill. */
      #custom-winmode { background: @pill-hover; border: 1px solid rgba(137, 180, 250, 0.5); border-radius: 10px; padding: 0 10px; margin: 4px 0 4px 5px; color: @txt-strong; font-weight: bold; }
      #custom-winmode.s { color: #f9e2af; }
      #custom-winmode.f { color: #89b4fa; }
      #custom-winmode:empty { background: transparent; border: none; padding: 0; margin: 0; min-width: 0; }
      #custom-inhibit, #tray, #mode, #scratchpad,
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
      #scratchpad { color: @txt-strong; margin: 4px 5px; }
      #clock { color: @txt; font-weight: bold; background: @pill; border: 1px solid @edge; border-radius: 10px; padding: 0 10px; margin: 4px 10px 4px 5px; }
      #custom-study { background: @pill; border: 1px solid @edge; border-radius: 10px; padding: 0 10px; margin: 4px 5px; font-weight: bold; }
      #custom-study.running { color: #89b4fa; }
      #custom-study.paused { color: #fab387; }
      #custom-study.idle { color: @muted; }
      #custom-inhibit.running { color: #89b4fa; }
      /* Pill chỉ có glyph (14px) thấp hơn pill chữ (18px) → thêm padding dọc. */
      #custom-inhibit { padding: 2px 10px; margin: 4px 4px 4px 2px; }
      #power-profiles-daemon { padding: 0 4px; }
      #bluetooth.off, #bluetooth.disabled, #bluetooth.no-controller { color: @muted; }
      #bluetooth.connected { color: #a6e3a1; }
      #custom-inhibit.manual { color: #fab387; }
      #custom-inhibit.idle { color: @muted; }
      #network.disconnected, #network.disabled { color: #f38ba8; }
      #battery.warning, #temperature.warning, #cpu.warning, #memory.warning { color: #fab387; }
      #battery.critical { color: #f38ba8; }
      #temperature.critical, #cpu.critical, #memory.critical { color: #f38ba8; animation: blink 1s linear infinite; }
      #battery.charging { color: #a6e3a1; font-weight: bold; }
      #battery.plugged { color: #a6e3a1; }
      #pulseaudio.muted { color: @muted; }
    '';
  };
}
