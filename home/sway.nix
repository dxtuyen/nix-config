{ pkgs, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    package = null; # Dùng sway từ NixOS module
    config = null; # Dùng hoàn toàn raw string trong extraConfig
    systemd.enable = true;

    extraConfig = ''
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
      set $term ghostty
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
      default_border normal 2
      default_floating_border pixel 2
      focus_follows_mouse yes
      workspace_auto_back_and_forth yes
      smart_borders off

      for_window [shell="xdg_shell"] title_format "%title (%app_id)"
      for_window [shell="x_wayland"] title_format "%class - %title"

      client.focused           #7aa2f7 #7aa2f7 #1a1b26 #bb9af7 #7aa2f7
      client.focused_inactive  #7aa2f7 #1a1b26 #c0caf5 #7aa2f7 #7aa2f7
      client.unfocused         #414868 #1a1b26 #c0caf5 #414868 #414868
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
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
      bindsym $mod+End exec systemctl poweroff
      bindsym $mod+Shift+o exec ~/.local/bin/lock-screen
      bindsym $mod+Shift+p exec systemctl suspend
      bindsym $mod+Control+p exec ~/.local/bin/cycle-power-profile
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

      # Workspaces
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
      bindsym $mod+bracketleft workspace prev
      bindsym $mod+bracketright workspace next

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
      bindsym $mod+t exec ~/.local/bin/quick-lang vi-en
      bindsym $mod+Shift+t exec ~/.local/bin/quick-lang en-vi
      bindsym $mod+Control+t exec ~/.local/bin/quick-lang polish
      bindsym Print exec grim -g "$(slurp)" - | wl-copy
      bindsym Mod1+Print exec grim - | wl-copy
      bindsym Shift+Print exec sh -c 'f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"; mkdir -p "$(dirname "$f")"; grim -g "$(slurp)" "$f" && wl-copy < "$f"'
      bindsym Ctrl+Print exec sh -c 'f="$HOME/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png"; mkdir -p "$(dirname "$f")"; grim "$f" && wl-copy < "$f"'

      # Media & Brightness keys
      bindsym XF86AudioRaiseVolume exec ~/.local/bin/media-notify volume-up
      bindsym XF86AudioLowerVolume exec ~/.local/bin/media-notify volume-down
      bindsym XF86AudioMute exec ~/.local/bin/media-notify volume-mute
      bindsym XF86AudioMicMute exec ~/.local/bin/media-notify mic-mute
      bindsym XF86MonBrightnessUp exec ~/.local/bin/media-notify brightness-up
      bindsym XF86MonBrightnessDown exec ~/.local/bin/media-notify brightness-down

      # Idle management
      exec swayidle -w timeout 300 '~/.local/bin/lock-screen' before-sleep '~/.local/bin/lock-screen' lock '~/.local/bin/lock-screen' unlock 'pkill -xu "$USER" -SIGUSR1 swaylock'
    '';
  };
}
