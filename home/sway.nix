{ pkgs, ... }:

let
  # Danh sách tên workspace dùng chung ở home/workspaces.nix
  ws = import ./workspaces.nix;
in
{
  wayland.windowManager.sway = {
    enable = true;
    package = null; # Dùng sway từ NixOS module
    config = null; # Dùng hoàn toàn raw string trong extraConfig
    systemd.enable = true;

    extraConfig = ''
      # 0. Dọn swayidle cũ trước khi chạy bản mới (exec_always: chạy lại mỗi lần reload,
      # nên không bao giờ kẹt ở bản cũ sau khi sửa config)
      exec_always pkill -x swayidle 2>/dev/null || true

      # 1. Đồng bộ biến màn hình & bộ gõ từ Sway vào Systemd & DBus
      exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway SWAYSOCK XMODIFIERS QT_IM_MODULE
      exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK XMODIFIERS QT_IM_MODULE

      # 2. Bắt đầu phiên làm việc (Waybar sẽ đợi 2 lệnh trên xong mới chạy)
      exec systemctl --user start sway-session.target

      set $mod Mod4
      set $left h
      set $down j
      set $up k
      set $right l
      set $term alacritty
      set $menu rofi -show drun

      # Wallpaper cycle
      exec ~/.local/bin/cycle-wallpaper

      # Applets & daemons
      exec nm-applet --indicator
      exec blueman-applet
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
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
      seat * xcursor_theme Bibata-Modern-Classic 24

      # Tokyo Night style
      gaps inner 7
      gaps outer 4
      gaps top 0
      default_border pixel 2
      default_floating_border pixel 2
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

      # Inhibit idle
      for_window [class="google-chrome"] inhibit_idle fullscreen

      # Keybindings - App & Session
      bindsym $mod+Return exec $term
      bindsym $mod+Shift+q kill
      bindsym $mod+d exec $menu
      bindsym $mod+Tab exec rofi -show window
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
      bindsym $mod+Shift+s exec ~/.local/bin/open-study-apps
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
      # Mỗi tên ở vị trí thứ N tự sinh: biến $wsN + phím $mod+N / $mod+Shift+N
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
            set $ws${n} "${name}"
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
        bindsym $left resize shrink width 10px
        bindsym $down resize grow height 10px
        bindsym $up resize shrink height 10px
        bindsym $right resize grow width 10px
        bindsym Escape mode "default"
        bindsym Return mode "default"
      }
      bindsym $mod+r mode "resize"

      # Custom Utilities & Screenshot
      bindsym $mod+p exec ~/.local/bin/pomodoro-menu
      bindsym $mod+Shift+p exec ~/.local/bin/power-menu
      bindsym $mod+t exec ~/.local/bin/quick-lang vi-en
      bindsym $mod+Shift+t exec ~/.local/bin/quick-lang en-vi
      bindsym $mod+g exec ~/.local/bin/dict-lookup
      bindsym $mod+Ctrl+t exec ~/.local/bin/toggle-touchpad
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

      # Idle management — 1 swayidle duy nhất quản lý toàn bộ chuỗi (chuẩn sway wiki + swayidle(1)).
      # exec_always: đảm bảo mỗi lần swaymsg reload, swayidle bản mới được chạy lại
      # (exec thường chỉ chạy 1 lần lúc khởi động → kẹt bản cũ như từng gặp).
      #   300s idle       → khóa màn hình (lock-screen dùng `swaylock -f`, trả về ngay)
      #   310s idle       → tắt màn (power off); có thao tác → bật lại nhưng vẫn khóa
      #   900s idle       → sleep (suspend) — màn đã tắt & khóa nên an toàn
      #   before-sleep    → luôn khóa lại trước khi ngủ (chuẩn swayidle(1))
      #   after-resume    → bật màn lại sau khi máy dậy
      #   lock / unlock   → logind báo khóa/mở khóa phiên (vd: loginctl lock-session, đóng nắp đã cấu hình suspend)
      # (swayidle tự reset khi có bất kỳ thao tác nào nên không bao giờ suspend khi đang dùng)
      exec_always swayidle -w \
        timeout 300 '~/.local/bin/lock-screen' \
        timeout 310 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
        timeout 900 'systemctl suspend' \
        before-sleep '~/.local/bin/lock-screen' \
        after-resume 'swaymsg "output * power on"' \
        lock '~/.local/bin/lock-screen' \
        unlock 'swaymsg "output * power on"'
    '';
  };
}
