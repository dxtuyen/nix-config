{ pkgs, ... }:

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
      set $term alacritty
      set $menu rofi -show drun

      # Wallpaper: lúc đăng nhập GIỮ nguyên ảnh phiên trước (--if-empty); nếu chưa
      # có ảnh (máy mới / cache trống) mới random. Đổi ảnh bất cứ lúc nào bằng
      # Alt+Tab (random) hoặc Alt+Shift+Tab (menu có thumbnail).
      exec ~/.local/bin/wallpaper-set --if-empty

      # Applets & daemons
      exec nm-applet --indicator
      exec blueman-applet
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

      # Tokyo Night style
      gaps inner 7
      gaps outer 4
      gaps top 0
      default_border pixel 2
      default_floating_border pixel 2
      # $mod + chuột trái/phải = move/resize cửa sổ float.
      floating_modifier $mod normal
      focus_follows_mouse yes
      smart_borders off

      client.focused           #7aa2f7 #364a82 #c0caf5 #bb9af7 #7aa2f7
      client.focused_inactive  #a9b1d6 #1a1b26 #c0caf5 #a9b1d6 #a9b1d6
      client.unfocused         #414868 #1a1b26 #565f89 #414868 #414868
      client.urgent            #ff9e64 #1a1b26 #ff9e64 #565f89 #ff9e64
      client.placeholder       #1a1b26 #1a1b26 #c0caf5 #565f89 #565f89
      client.background        #1a1b26

      # Floating rules
      for_window [app_id="pavucontrol"] floating enable, resize set width 30 ppt height 40 ppt
      for_window [app_id="blueman-manager"] floating enable, resize set width 40 ppt height 40 ppt
      for_window [app_id="file-roller"] floating enable
      for_window [title="htop"] floating enable, resize set width 50 ppt height 70 ppt

      # GoldenDict float như popup (mod+g bật/tắt; đóng = ẩn về tray).
      for_window [app_id="io.github.xiaoyifang.goldendict_ng"] floating enable, resize set width 50 ppt height 65 ppt
      # Sioyek: cửa sổ mới hiện ở workspace đang focus.
      for_window [class="(?i)^sioyek$"] move container to workspace current
      for_window [app_id="(?i)^sioyek$"] move container to workspace current

      # Thunar float kiểu popup (mod+Shift+space để tiled lại).
      for_window [class="(?i)^thunar$"] floating enable, resize set width 40 ppt height 65 ppt
      for_window [app_id="(?i)^thunar$"] floating enable, resize set width 40 ppt height 65 ppt

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

      # Anki luôn mở vào workspace 7.
      for_window [class="(?i)^anki$"] move container to workspace number 7, workspace number 7
      for_window [app_id="(?i)^anki$"] move container to workspace number 7, workspace number 7

      # Inhibit idle
      for_window [class="google-chrome"] inhibit_idle fullscreen

      # Keybindings - App & Session
      bindsym $mod+Return exec $term
      bindsym $mod+Shift+q kill
      bindsym $mod+d exec $menu
      bindsym $mod+Tab exec rofi -show window

      # Wallpaper: Alt+Tab đổi ảnh random, Alt+Shift+Tab menu chọn ảnh.
      # ($mod+w đã dùng cho layout tabbed.)
      bindsym Mod1+w exec ~/.local/bin/wallpaper-set
      bindsym Mod1+Shift+w exec ~/.local/bin/wallpaper-menu
      # $mod+y: yazi (file manager terminal) ở thư mục hiện tại — dùng chung.
      # $mod+Shift+y: mở THẲNG thư mục ảnh nền để thêm/xoá ảnh cho nhanh
      # (thư mục ngoài repo, do home.activation tạo sẵn nên không lỗi).
      bindsym $mod+y exec $term -e yazi
      bindsym $mod+Shift+y exec $term -e yazi $HOME/Pictures/wallpapers
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
      bindsym $mod+Shift+n exec ~/.local/bin/toggle-wlsunset

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

      # Workspaces — tên tập trung ở home/workspaces.nix (sửa một chỗ).
      # Mỗi tên ở vị trí thứ N tự sinh: phím $mod+N / $mod+Shift+N
      # (vd tên đầu danh sách → $mod+1, thứ hai → $mod+2...).
      # Các số còn lại đến 10 tự sinh phím trỏ tới workspace số tương ứng
      # (phím 0 = workspace 10).
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

      mode "resize" {
        bindsym $left resize shrink width 20px
        bindsym $down resize grow height 20px
        bindsym $up resize shrink height 20px
        bindsym $right resize grow width 20px
        bindsym Escape mode "default"
        bindsym Return mode "default"
      }
      bindsym $mod+r mode "resize"

      # Custom Utilities & Screenshot
      bindsym $mod+p exec ~/.local/bin/pomodoro-menu
      bindsym $mod+Shift+p exec ~/.local/bin/power-menu
      # quick-lang — bộ phím chữ "t" (xem docs/02):
      #   t            → English sạch (smart: VI/EN/trộn tự nhận dạng; EN đã đúng
      #                  → nguyên văn, có lỗi → sửa)
      #   Shift+t      → tiếng Việt tự nhiên
      #   Ctrl+Shift+t → ép sửa English (không auto-detect)
      # Tag ngữ cảnh [phi]/[sci]/[lit]/[cas]/[lĩnh vực] đặt ở ĐẦU văn bản bôi.
      # Gemini hết quota → script tự fallback Google Translate (không cần phím).
      bindsym $mod+t exec ~/.local/bin/quick-lang vi-en
      bindsym $mod+Shift+t exec ~/.local/bin/quick-lang en-vi
      bindsym $mod+Ctrl+Shift+t exec ~/.local/bin/quick-lang fix
      bindsym $mod+Shift+r exec ~/.local/bin/quick-net-reload
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

      # swayidle chạy qua systemd (khóa 300s → tắt màn 310s → ngủ 900s khi
      # dùng pin). Phiên Focus chạy → study stop service này, xong tự start lại.
    '';
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
