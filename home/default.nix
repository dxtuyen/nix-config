{ pkgs, userName, ... }:

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";
  };

  home.packages = with pkgs; [
    alacritty
    rofi
    wlsunset
    grim
    slurp
    wl-clipboard
    swaylock
    swayidle
    libnotify
    pavucontrol
    brightnessctl
    translate-shell
    wireplumber
    thunar
    networkmanagerapplet
    blueman
    polkit_gnome
    google-chrome
    zathura
    calibre
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;
    config = null;
    systemd.enable = true;
    extraConfig = ''
      set $mod Mod4
      set $left h
      set $down j
      set $up k
      set $right l
      set $term alacritty
      set $menu rofi -show combi -combi-modes drun#run -modes combi

      output * bg #0a0e17 solid_color
      exec nm-applet --indicator
      exec blueman-applet
      exec /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1
      exec wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8

      input type:touchpad {
        pointer_accel 0.6
        accel_profile adaptive
        natural_scroll disabled
        scroll_method two_finger
        tap enabled
        drag enabled
        dwt enabled
      }
      seat * hide_cursor 7000

      bindsym $mod+Return exec $term
      bindsym $mod+q kill
      bindsym $mod+d exec $menu
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
      bindsym $mod+Shift+o exec ~/.local/bin/lock-screen
      bindsym $mod+Shift+p exec sh -c '~/.local/bin/lock-screen & sleep 1; systemctl suspend'
      bindsym $mod+End exec systemctl poweroff

      bindsym $mod+$left focus left
      bindsym $mod+$down focus down
      bindsym $mod+$up focus up
      bindsym $mod+$right focus right
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right
      bindsym $mod+Shift+$left move left
      bindsym $mod+Shift+$down move down
      bindsym $mod+Shift+$up move up
      bindsym $mod+Shift+$right move right
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right

      bindsym $mod+1 workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+9 workspace number 9
      bindsym $mod+0 workspace number 10
      bindsym $mod+Shift+1 move container to workspace number 1
      bindsym $mod+Shift+2 move container to workspace number 2
      bindsym $mod+Shift+3 move container to workspace number 3
      bindsym $mod+Shift+4 move container to workspace number 4
      bindsym $mod+Shift+5 move container to workspace number 5
      bindsym $mod+Shift+6 move container to workspace number 6
      bindsym $mod+Shift+7 move container to workspace number 7
      bindsym $mod+Shift+8 move container to workspace number 8
      bindsym $mod+Shift+9 move container to workspace number 9
      bindsym $mod+Shift+0 move container to workspace number 10

      bindsym $mod+b splith
      bindsym $mod+v splitv
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split
      bindsym $mod+f fullscreen
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+space focus mode_toggle
      bindsym $mod+a focus parent
      bindsym $mod+Shift+minus move scratchpad
      bindsym $mod+minus scratchpad show
      mode "resize" {
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px
        bindsym Escape mode "default"
        bindsym Return mode "default"
      }
      bindsym $mod+r mode "resize"

      bindsym $mod+t exec ~/.local/bin/quick-lang vi-en
      bindsym $mod+Shift+t exec ~/.local/bin/quick-lang en-vi
      bindsym $mod+Control+t exec ~/.local/bin/quick-lang polish
      bindsym Print exec grim -g "$(slurp)" - | wl-copy
      bindsym Mod1+Print exec grim - | wl-copy
      bindsym Shift+Print exec sh -c 'f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"; mkdir -p "$(dirname "$f")"; grim -g "$(slurp)" "$f" && wl-copy < "$f"'
      bindsym Ctrl+Print exec sh -c 'f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"; mkdir -p "$(dirname "$f")"; grim "$f" && wl-copy < "$f"'
      bindsym XF86AudioRaiseVolume exec ~/.local/bin/media-notify volume-up
      bindsym XF86AudioLowerVolume exec ~/.local/bin/media-notify volume-down
      bindsym XF86AudioMute exec ~/.local/bin/media-notify volume-mute
      bindsym XF86AudioMicMute exec ~/.local/bin/media-notify mic-mute
      bindsym XF86MonBrightnessUp exec ~/.local/bin/media-notify brightness-up
      bindsym XF86MonBrightnessDown exec ~/.local/bin/media-notify brightness-down

      exec swayidle -w timeout 300 '~/.local/bin/lock-screen' before-sleep 'swaylock -f -c 0a0e17' lock 'swaylock -f -c 0a0e17' unlock 'pkill -xu "$USER" -SIGUSR1 swaylock'
    '';
  };

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
      #workspaces button { padding: 0 7px; color: #718079; }
      #workspaces button.focused, #workspaces button.active, #clock { color: #4af626; font-weight: bold; }
      #window, #scratchpad { margin: 0 5px; color: #a8d9a0; }
      #idle_inhibitor, #pulseaudio, #network, #power-profiles-daemon, #cpu, #memory, #temperature, #backlight, #battery, #tray { padding: 0 10px; color: #a8d9a0; }
      #battery.warning, #temperature.warning { color: #f5b84b; }
      #battery.critical, #temperature.critical { color: #ff5555; }
      #network.disconnected, #pulseaudio.muted { color: #718079; }
    '';
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      "app-name=quick-lang".default-timeout = 7000;
      "app-name=volume".default-timeout = 2000;
      "app-name=brightness".default-timeout = 2000;
    };
  };

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "sway-session.target" ];
      After = [ "sway-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "sway-session.target" ];
  };

  xdg.configFile = {
    "fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=unikey
      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=
      [Groups/0/Items/1]
      Name=unikey
      Layout=
      [GroupOrder]
      0=Default
    '';
    "fcitx5/conf/unikey.conf".text = ''
      [Config]
      InputMethod=0
      OutputCharset=0
      SpellCheck=True
      Macro=True
      ProcessWAtBegin=True
      AutoNonVnRestore=True
      ModernStyle=False
      FreeMarking=True
      SurroundingText=True
      ModifySurroundingText=False
      DisplayUnderline=True
    '';
  };

  home.file = {
    ".local/bin/lock-screen" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        swayidle -w timeout 10 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' &
        watcher=$!
        swaylock -c 0a0e17
        kill "$watcher" 2>/dev/null || true
        swaymsg "output * power on"
      '';
    };
    ".local/bin/refresh-session" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        pkill wlsunset 2>/dev/null || true
        wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8 &
        swaymsg reload
      '';
    };
    ".local/bin/quick-lang" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        mode="''${1:-vi-en}"
        text="$(wl-paste -p 2>/dev/null || wl-paste 2>/dev/null || true)"
        [ -n "''${text//[[:space:]]/}" ] || { notify-send -a quick-lang -t 7000 "Quick Lang" "Không có văn bản nào được chọn hoặc copy."; exit 1; }
        case "$mode" in
          vi-en) result="$(trans -b vi:en "$text")"; printf %s "$result" | wl-copy; notify-send -a quick-lang -t 7000 "VI → EN" "$result" ;;
          en-vi) result="$(trans -b en:vi "$text")"; printf %s "$result" | wl-copy; notify-send -a quick-lang -t 7000 "EN → VI" "$result" ;;
          polish) printf '%s' "Rewrite and improve this English text. Return only the improved version:\n\n$text" | wl-copy; notify-send -a quick-lang -t 7000 "English Polish" "Prompt đã được copy." ;;
        esac
      '';
    };
    ".local/bin/media-notify" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        set -eu

        # Sway runs one process per key press. Serialize them so every request
        # updates the same notification instead of racing to create a new one.
        if [ "''${MEDIA_NOTIFY_LOCKED:-}" != 1 ]; then
          exec env MEDIA_NOTIFY_LOCKED=1 ${pkgs.util-linux}/bin/flock \
            "''${XDG_RUNTIME_DIR:?}/media-notify.lock" "$0" "$@"
        fi

        # A replacement ID must be one assigned by mako, rather than a fixed
        # arbitrary number. Keep the most recently assigned ID for each kind
        # of notification so rapid key presses update the visible popup.
        notify_replace() {
          name="$1"
          shift
          id_file="''${XDG_RUNTIME_DIR:?}/media-notify-''${name}.id"
          replace_id=""

          if [ -r "$id_file" ]; then
            read -r replace_id < "$id_file" || true
            case "$replace_id" in
              *[!0-9]*|"") replace_id="" ;;
            esac
          fi

          if [ -n "$replace_id" ]; then
            notification_id="$(notify-send -p -r "$replace_id" "$@")"
          else
            notification_id="$(notify-send -p "$@")"
          fi

          case "$notification_id" in
            *[!0-9]*|"") ;;
            *) printf '%s\n' "$notification_id" > "$id_file" ;;
          esac
        }

        notify_volume() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
          volume="$(printf '%s\n' "$status" | awk '{ printf "%d", ($2 * 100) + 0.5 }')"
          case "$status" in
            *MUTED*) notify_replace volume -a volume -t 2000 "Volume" "Muted" ;;
            *) notify_replace volume -a volume -t 2000 "Volume" "''${volume}%" ;;
          esac
        }

        notify_microphone() {
          status="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
          case "$status" in
            *MUTED*) notify_replace microphone -a volume -t 2000 "Microphone" "Muted" ;;
            *) notify_replace microphone -a volume -t 2000 "Microphone" "On" ;;
          esac
        }

        case "''${1:?missing action}" in
          volume-up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; notify_volume ;;
          volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; notify_volume ;;
          volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; notify_volume ;;
          mic-mute)
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            notify_microphone
            ;;
          brightness-up)
            brightnessctl set +10%
            notify_replace brightness -a brightness -t 2000 "Brightness" "$(brightnessctl -m | cut -d, -f4)"
            ;;
          brightness-down)
            brightnessctl set 10%-
            notify_replace brightness -a brightness -t 2000 "Brightness" "$(brightnessctl -m | cut -d, -f4)"
            ;;
        esac
      '';
    };
  };

  programs.home-manager.enable = true;
}
