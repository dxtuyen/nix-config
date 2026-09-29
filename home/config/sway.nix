{ config, pkgs, ... }:

let
  ws = import ./workspaces.nix; # tên workspace dùng chung với Waybar
in
{
  wayland.windowManager.sway = {
    enable = true;
    package = null; # dùng sway từ NixOS module
    config = null; # cấu hình hoàn toàn bằng extraConfig
    systemd.enable = true;

    extraConfig = ''
      # Đồng bộ biến Sway vào systemd/DBus trước khi start session.
      exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway SWAYSOCK XMODIFIERS QT_IM_MODULE
      exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK XMODIFIERS QT_IM_MODULE

      exec systemctl --user start sway-session.target

      set $mod Mod4
      set $left h
      set $down j
      set $up k
      set $right l
      set $term foot
      set $menu rofi -show drun

      # Wallpaper: mỗi lần bật máy vào Sway → đổi ảnh nền random (khác
      # ảnh đang hiển thị). KHÔNG dùng --if-empty nữa (cờ đó = giữ ảnh phiên
      # trước). Script tự start + chờ awww-daemon sẵn sàng, nên gọi thẳng
      # ở đây là an toàn.
      exec ~/.local/bin/wallpaper-set

      # Applets & daemons
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      exec wlsunset -t 4000 -T 6500 -l 21.0 -L 105.8

      input type:touchpad {
        pointer_accel 0.6
        accel_profile adaptive
        natural_scroll enabled
        scroll_method two_finger
        tap enabled
        drag enabled
        dwt enabled
      }
      seat * hide_cursor 7000
      seat * xcursor_theme Bibata-Modern-Classic 24

      # Catppuccin Mocha style
      gaps inner 7
      gaps outer 4
      gaps top 0
      default_border pixel 2
      default_floating_border pixel 2
      # $mod + chuột trái/phải = move/resize cửa sổ float.
      floating_modifier $mod normal
      focus_follows_mouse yes
      smart_borders off

      client.focused           #89b4fa #313244 #cdd6f4 #cba6f7 #89b4fa
      client.focused_inactive  #bac2de #1e1e2e #cdd6f4 #bac2de #bac2de
      client.unfocused         #585b70 #1e1e2e #6c7086 #585b70 #585b70
      client.urgent            #fab387 #1e1e2e #fab387 #6c7086 #fab387
      client.placeholder       #1e1e2e #1e1e2e #cdd6f4 #6c7086 #6c7086
      client.background        #1e1e2e

      # Floating rules
      for_window [app_id="pavucontrol"] floating enable, resize set width 30 ppt height 40 ppt
      for_window [app_id="bluetui"] floating enable, resize set 750 px 500 px
      # RemNote: popup scratchpad giữa màn hình. Vào scratchpad ngay khi mở nên
      # $mod+minus ẩn/hiện được và cửa sổ bám theo workspace hiện tại.
      # KHÔNG resize: "move scratchpad" tự float + size mặc định của Sway.
      for_window [class="(?i).*remnote.*"] move scratchpad, scratchpad show
      for_window [app_id="(?i).*remnote.*"] move scratchpad, scratchpad show
      for_window [title="htop"] floating enable, resize set width 50 ppt height 70 ppt

      # GoldenDict float như popup (mod+g bật/tắt; đóng = ẩn về tray).
      for_window [app_id="io.github.xiaoyifang.goldendict_ng"] floating enable, resize set width 50 ppt height 65 ppt
      # Sioyek: cửa sổ mới hiện ở workspace đang focus.
      for_window [class="(?i)^sioyek$"] move container to workspace current
      for_window [app_id="(?i)^sioyek$"] move container to workspace current

      # Foliate: app_id theo .desktop; khai cả `class` để phòng XWayland.
      for_window [class="(?i)^foliate$"] move container to workspace current
      for_window [app_id="(?i)^com\.github\.johnfactotum\.foliate$"] move container to workspace current

      # Thunar float kiểu popup (mod+Shift+space để tiled lại).
      for_window [class="(?i)^thunar$"] floating enable, resize set width 40 ppt height 65 ppt
      for_window [app_id="(?i)^thunar$"] floating enable, resize set width 40 ppt height 65 ppt

      # Yazi chạy trong foot (app_id vẫn là "foot") → phải match theo TITLE mà
      # script đặt ra. Chỉ cửa sổ này float, terminal thường không ảnh hưởng.
      for_window [title="(?i)^yazi-popup"] floating enable, resize set 1000 px 700 px

      # Foot terminal scratchpad: một cửa sổ riêng, giữ phiên shell khi ẩn; luôn
      # nằm trong scratchpad để $mod+minus ẩn/hiện và $mod+grave chỉ focus.
      # KHÔNG resize: "move scratchpad" tự float + size mặc định của Sway.
      for_window [app_id="scratchpad-terminal"] move scratchpad, scratchpad show

      # Wi-Fi popup: wifitui (hỗ trợ toggle radio, fuzzy search, rescan)
      for_window [app_id="wifitui"] floating enable, resize set 750 px 500 px

      # Dialog/popup rules
      for_window [window_role="pop-up"] floating enable
      for_window [window_role="bubble"] floating enable
      for_window [window_role="task_dialog"] floating enable
      for_window [window_role="Preferences"] floating enable
      for_window [window_type="dialog"] floating enable
      for_window [window_type="menu"] floating enable
      for_window [window_role="About"] floating enable
      for_window [title="Save File"] floating enable

      # Chrome Picture-in-Picture
      for_window [title="Picture in picture"] floating enable, sticky enable, resize set width 350 px height 197 px, move position 1530 px 800 px

      # VS Code luôn mở vào workspace 3.code.
      for_window [class="(?i)^code$"] move container to workspace number 3.code, workspace number 3.code
      for_window [app_id="(?i)^code$"] move container to workspace number 3.code, workspace number 3.code

      # Inhibit idle
      for_window [class="google-chrome"] inhibit_idle fullscreen

      # Keybindings - App & Session
      bindsym $mod+Return exec $term
      # $mod+grave: focus terminal scratchpad (bấm lại KHÔNG ẩn; ẩn bằng $mod+minus).
      bindsym $mod+grave exec ~/.local/bin/scratchpad-terminal
      bindsym $mod+q exec ${pkgs.swayr}/bin/swayr quit-window
      bindsym $mod+d exec $menu
      # Mod+Tab: quay lại cửa sổ vừa dùng; Mod+m: menu MRU;
      # Mod+Shift+q: kill ngay cửa sổ đang focus.
      bindsym $mod+Tab exec ${pkgs.swayr}/bin/swayr switch-to-urgent-or-lru-window
      bindsym $mod+m exec ${pkgs.swayr}/bin/swayr switch-window
      bindsym $mod+Shift+q kill

      # Menu ảnh: Mod+Shift+m · menu scratchpad: Mod+n · đổi ảnh: Mod+Shift+w.
      # ~/Pictures/wallpapers (lưới thumbnail, phím ←→↑↓ duyệt ảnh).
      bindsym $mod+Shift+m exec ~/.local/bin/wallpaper-menu
      bindsym $mod+n exec ~/.local/bin/scratchpad-menu
      bindsym $mod+Shift+w exec ~/.local/bin/wallpaper-set
      # $mod+r: focus RemNote scratchpad (bấm lại KHÔNG ẩn; ẩn bằng $mod+minus).
      bindsym $mod+r exec ~/.local/bin/remnote-focus
      # $mod+y: yazi dạng POPUP nhỏ; gõ `yazi` trong terminal thì cửa sổ thường.
      bindsym $mod+y exec ~/.local/bin/yazi-open
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
      # Focus movement
      bindsym $mod+$left focus left
      bindsym $mod+$down focus down
      bindsym $mod+$up focus up
      bindsym $mod+$right focus right
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right

      # Container movement
      bindsym $mod+Shift+$left move left
      bindsym $mod+Shift+$down move down
      bindsym $mod+Shift+$up move up
      bindsym $mod+Shift+$right move right
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right

      # Tên tập trung ở home/config/workspaces.nix: vị trí thứ N tự sinh $mod+N /
      # $mod+Shift+N (tên đầu → $mod+1…). Số còn lại đến 10 sinh tương ứng (0 = 10).
      ${builtins.concatStringsSep "\n" (
        pkgs.lib.imap1 (
          i: name:
          let
            n = toString i;
            key = if i == 10 then "0" else n;
          in
          ''
            bindsym $mod+${key} workspace number ${name}
            bindsym $mod+Shift+${key} move container to workspace number ${name}''
        ) ws
      )}
      ${builtins.concatStringsSep "\n" (
        map (
          i:
          let
            n = toString i;
            key = if i == 10 then "0" else n;
          in
          ''
            bindsym $mod+${key} workspace number ${n}
            bindsym $mod+Shift+${key} move container to workspace number ${n}''
        ) (pkgs.lib.range (builtins.length ws + 1) 10)
      )}
      bindsym $mod+u workspace prev
      bindsym $mod+i workspace next

      # Layout & Window State
      bindsym $mod+b splith
      bindsym $mod+v splitv
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split
      bindsym $mod+f fullscreen
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+space focus mode_toggle
      bindsym $mod+a focus parent
      bindsym $mod+Shift+a focus child
      bindsym $mod+Shift+minus move scratchpad
      bindsym $mod+minus scratchpad show

      # Custom Utilities & Screenshot
      bindsym $mod+o exec ~/.local/bin/util-menu
      bindsym $mod+p exec ~/.local/bin/power-menu
      bindsym $mod+c exec ~/.local/bin/countdown-menu
      # quick-lang: t = English sạch · Shift+t = tiếng Việt · Ctrl+t = ép
      # sửa English. Tag [phi]/[sci]/[lit]/[cas] đầu văn bản bôi chọn ngữ cảnh.
      bindsym $mod+t exec ~/.local/bin/quick-lang vi-en
      bindsym $mod+Shift+t exec ~/.local/bin/quick-lang en-vi
      bindsym $mod+Ctrl+t exec ~/.local/bin/quick-lang fix
      # dict-toggle: bật/tắt GoldenDict float; đóng = ẩn về tray
      bindsym $mod+g exec ~/.local/bin/dict-toggle
      bindsym $mod+Mod1+t exec ~/.local/bin/toggle-touchpad
      bindsym $mod+Print exec ~/.local/bin/screenshot-menu
      bindsym --no-repeat Print exec ~/.local/bin/screenshot selection-clipboard
      bindsym --no-repeat Mod1+Print exec ~/.local/bin/screenshot fullscreen-clipboard
      bindsym --no-repeat Shift+Print exec ~/.local/bin/screenshot selection-save
      bindsym --no-repeat Ctrl+Print exec ~/.local/bin/screenshot fullscreen-save

      # Media & Brightness keys
      bindsym XF86AudioRaiseVolume exec ~/.local/bin/media-notify volume-up
      bindsym XF86AudioLowerVolume exec ~/.local/bin/media-notify volume-down
      bindsym XF86AudioMute exec ~/.local/bin/media-notify volume-mute
      bindsym XF86AudioMicMute exec ~/.local/bin/media-notify mic-mute
      bindsym XF86MonBrightnessUp exec ~/.local/bin/media-notify brightness-up
      bindsym XF86MonBrightnessDown exec ~/.local/bin/media-notify brightness-down

      # swayidle (systemd): khoá 300s → tắt màn 310s → ngủ 900s khi dùng pin.
      # Phiên Focus chạy → study stop service này, xong tự start lại.
    '';
  };

  # swayr giữ format mặc định cho ứng dụng thường; wrapper chỉ ẩn app ID PWA.
  xdg.configFile."swayr/config.toml".text = ''
    [menu]
    executable = "${config.home.homeDirectory}/.local/bin/swayr-rofi-menu"
    args = ["{prompt}"]

    [format]
    window_format = "{app_name} — {title}\u0000icon\u001f{app_icon}"
    html_escape = true
    icon_dirs = [
      "${config.home.homeDirectory}/.local/share/icons/hicolor/16x16/apps",
      "${config.home.homeDirectory}/.local/share/icons/hicolor/32x32/apps",
      "${config.home.homeDirectory}/.local/share/icons/hicolor/48x48/apps",
      "${config.home.homeDirectory}/.local/share/icons/hicolor/64x64/apps",
      "${config.home.homeDirectory}/.local/share/icons/hicolor/128x128/apps",
      "${config.home.homeDirectory}/.local/share/icons/hicolor/256x256/apps",
      "${config.home.homeDirectory}/.local/share/icons/hicolor/scalable/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/16x16/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/32x32/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/48x48/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/64x64/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/128x128/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/256x256/apps",
      "/etc/profiles/per-user/${config.home.username}/share/icons/hicolor/scalable/apps",
      "/run/current-system/sw/share/icons/hicolor/16x16/apps",
      "/run/current-system/sw/share/icons/hicolor/32x32/apps",
      "/run/current-system/sw/share/icons/hicolor/48x48/apps",
      "/run/current-system/sw/share/icons/hicolor/64x64/apps",
      "/run/current-system/sw/share/icons/hicolor/128x128/apps",
      "/run/current-system/sw/share/icons/hicolor/256x256/apps",
      "/run/current-system/sw/share/icons/hicolor/scalable/apps",
      "/run/current-system/sw/share/icons/Adwaita/48x48/apps",
      "/run/current-system/sw/share/icons/Adwaita/scalable/apps",
      "/run/current-system/sw/share/pixmaps",
    ]
  '';

  # Ghi lịch sử focus trong suốt phiên Sway; target được start sau khi import SWAYSOCK.
  systemd.user.services.swayrd = {
    Unit = {
      Description = "Swayr window history daemon";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swayr}/bin/swayrd";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "sway-session.target" ];
  };

  # systemd cho log journald + tự hồi sinh khi crash + dừng theo phiên Sway.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle manager for Wayland (lock → screen off → suspend)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # Diệt instance cũ trước khi start (dấu "-" = không có gì để diệt vẫn OK).
      ExecStartPre = "-${pkgs.procps}/bin/pkill -x swayidle";
      # PATH cho lệnh con swayidle spawn (swaymsg, systemctl, lock-screen).
      Environment = [
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/doxuantuyen/bin:%h/.local/bin"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 300 '%h/.local/bin/lock-screen' \
          timeout 310 'swaymsg "output * power off"' \
          resume 'swaymsg "output * power on"' \
          timeout 900 '%h/.local/bin/idle-suspend' \
          before-sleep '%h/.local/bin/lock-screen' \
          after-resume 'swaymsg "output * power on"' \
          lock '%h/.local/bin/lock-screen' \
          unlock 'swaymsg "output * power on"'
      '';
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}
