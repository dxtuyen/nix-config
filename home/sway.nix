{ pkgs, ... }:

{
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

      output * bg ${./../wallpapers/nixos.jpg} fill
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
      bindsym $mod+Shift+q kill
      bindsym $mod+d exec $menu
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes, exit sway' 'swaymsg exit'
      bindsym $mod+End exec systemctl poweroff
      bindsym $mod+Shift+o exec ~/.local/bin/lock-screen
      bindsym $mod+Shift+p exec systemctl suspend
      bindsym $mod+Control+p exec ~/.local/bin/cycle-power-profile
      bindsym $mod+Shift+n exec ~/.local/bin/toggle-wlsunset

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
      bindsym $mod+Tab exec ~/.local/bin/workspace-new
      bindsym $mod+Control+h workspace prev
      bindsym $mod+Control+l workspace next

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

      exec swayidle -w timeout 300 '~/.local/bin/lock-screen' before-sleep 'swaylock -f -i ${./../wallpapers/nixos.jpg}' lock 'swaylock -f -i ${./../wallpapers/nixos.jpg}' unlock 'pkill -xu "$USER" -SIGUSR1 swaylock'
    '';
  };
}
