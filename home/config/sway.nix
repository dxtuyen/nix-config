{ pkgs, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    package = null; # use Sway from the NixOS module
    config = null; # configure everything via extraConfig
    systemd.enable = true;

    extraConfig = ''
      # Export Sway variables into systemd/DBus before starting the session.
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

      # Wallpaper: each time Sway starts -> set a random wallpaper (different
      # from the current one). Do NOT pass --if-empty anymore (that flag keeps
      # the previous session's image). The script starts itself and waits for
      # the awww daemon, so calling it directly here is safe.
      exec ~/.local/bin/wallpaper-set

      # Applets & daemons
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      # Night light (wlsunset): khôi phục mode đã chọn trong menu Display
      # (~/.local/state/wlsunset-mode) thay vì hardcode Natural.
      exec ~/.local/bin/wlsunset-apply

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
      # $mod + left/right mouse button = move/resize floating windows.
      floating_modifier $mod normal
      focus_follows_mouse yes
      # focus_on_window_activation: keep Sway's default (`urgent`) — apps
      # requesting focus only get the orange border, no focus jump (the extra
      # `focus` line added this morning was removed).
      smart_borders off

      # Focus border: bright blue (#89b4fa, ~7.8:1 vs base). Keep focused_inactive
      # dimmer than focused (overlay0, not the old bright subtext1) so the window
      # that actually holds focus always stands out in split/tabbed layouts.
      client.focused           #89b4fa #313244 #cdd6f4 #cba6f7 #89b4fa
      client.focused_inactive  #6c7086 #1e1e2e #cdd6f4 #6c7086 #6c7086
      client.unfocused         #585b70 #1e1e2e #6c7086 #585b70 #585b70
      client.urgent            #fab387 #1e1e2e #fab387 #6c7086 #fab387
      client.placeholder       #1e1e2e #1e1e2e #cdd6f4 #6c7086 #6c7086
      client.background        #1e1e2e

      # Floating rules
      # pavucontrol: GTK uses reverse-DNS as app_id (org.pulseaudio.pavucontrol),
      # but other packaged builds may use just "pavucontrol" -> match both.
      for_window [app_id="(?i)^(org[.]pulseaudio[.])?pavucontrol$"] floating enable, resize set width 30 ppt height 40 ppt
      for_window [app_id="bluetui"] floating enable, resize set 750 px 500 px
      # RemNote: opens as a centered floating popup by default (not a scratchpad).
      # RemNote AppImage runs via XWayland -> app_id is None, class is "RemNote".
      # Keep both rules: app_id covers native Wayland builds, class covers XWayland.
      for_window [app_id="(?i).*remnote.*"] floating enable, resize set width 1000 px height 700 px, move position center
      for_window [class="(?i).*remnote.*"] floating enable, resize set width 1000 px height 700 px, move position center

      # Obsidian: opens as a centered floating popup by default, like RemNote/TickTick.
      # Electron's app_id CHANGES WITH THE INSTALL METHOD (checked in /nix/store):
      #   md.obsidian.Obsidian — Nix-generated .desktop
      #   md.Obsidian          — Obsidian's original .desktop
      #   obsidian             — AppImage/Flatpak
      # -> match by name to be safe instead of hard-coding this machine's app_id.
      # No `class` here: Electron runs native Wayland so class is always None.
      for_window [app_id="(?i)^(md([.]obsidian)?[.]obsidian|obsidian)$"] floating enable, resize set width 1000 px height 700 px, move position center
      for_window [title="htop"] floating enable, resize set width 50 ppt height 70 ppt

      # GoldenDict floats as a popup (mod+g toggles; closing = hide to tray).
      for_window [app_id="io.github.xiaoyifang.goldendict_ng"] floating enable, resize set width 50 ppt height 65 ppt
      # Sioyek: new windows open on the focused workspace.
      for_window [app_id="(?i)^sioyek$"] move container to workspace current

      # Foliate: app_id theo .desktop.
      for_window [app_id="(?i)^com\.github\.johnfactotum\.foliate$"] move container to workspace current

      # Thunar floats as a popup (mod+Shift+space to tile it again). GTK3 runs
      # native Wayland so match app_id only; the desktop entry has no StartupWMClass.
      for_window [app_id="(?i)^thunar$"] floating enable, resize set width 40 ppt height 65 ppt

      # Yazi popup (app_id yazi-popup, set by yazi-open). Toggle with $mod+y;
      # $mod+Shift+minus stashes it, $mod+equal / $mod+Shift+equal / $mod+Tab brings it back.
      for_window [app_id="(?i)^yazi-popup$"] floating enable, resize set 1000 px 700 px

      # Foot terminal scratchpad: a separate window that keeps its shell session
      # while hidden; $mod+grave toggles it, $mod+equal shows it too.
      # Do NOT resize: "move scratchpad" already floats it at Sway's default size.
      for_window [app_id="scratchpad-terminal"] move scratchpad, scratchpad show

      # Wi-Fi popup: wifitui (supports radio toggle, fuzzy search, rescan)
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

      # File chooser served by xdg-desktop-portal-gtk: a SEPARATE, SHARED process,
      # so it cannot set a parent toplevel (journal: "Failed to associate portal
      # window with parent window") → Sway does NOT auto-float it. Matching this
      # app_id covers EVERY app that routes dialogs through the portal (Obsidian,
      # Electron, GTK apps with GTK_USE_PORTAL=1…), so no per-app rule is needed.
      for_window [app_id="(?i)^xdg-desktop-portal-gtk$"] floating enable, move position center

      # Chrome Picture-in-Picture
      for_window [title="Picture in picture"] floating enable, sticky enable, resize set width 350 px height 197 px, move position 1530 px 800 px

      # TickTick (PWA) -> opens as a centered floating popup by default. A PWA's
      # app_id is a hash of SHA256(start_url) + profile name (app_id_helpers.cc),
      # so it is NOT stable: changing Chrome profile/URL/version or reinstalling
      # on another machine changes the id.
      # Find the app_id on another machine: ls ~/.local/share/applications/chrome-*-Default.desktop
      # or open the PWA then: swaymsg -t get_tree | jq -r '..|objects|select(.app_id?)|.app_id'
      # Do NOT hard-code the hash: it changes with URL + profile name + Chrome
      # version, and reinstalling elsewhere makes the popup disappear. This regex
      # matches every "Default"-profile PWA (regular Chrome windows have no
      # -Default suffix so they are not caught by mistake).
      # If you use a differently named profile (e.g. "Profile 1"), add the matching suffix.
      for_window [app_id="(?i)^chrome-[a-z0-9]+-Default$"] floating enable, resize set width 1000 px height 700 px, move position center

      # Inhibit idle
      for_window [app_id="(?i)^google-chrome$"] inhibit_idle fullscreen

      # Keybindings - App & Session
      bindsym $mod+Return exec $term
      # $mod+grave: focus the scratchpad terminal (press again while focused -> stash
      # it back into the scratchpad). It is the only scratchpad terminal kept
      # (obsidian-focus was removed).
      bindsym $mod+grave exec ~/.local/bin/scratchpad-terminal
      bindsym $mod+d exec $menu
      # Alt+Tab: urgent or most-recent window (swayr LRU).
      # $mod+Tab: windows AWAY (hidden scratchpad + popups on other workspaces);
      #   Enter brings one back to the current workspace.
      # $mod+Shift+Tab: REGULAR windows only (no scratchpad, no popups — those have
      #   their own keys); Enter jumps to it, Shift+Enter pulls it here.
      # $mod+p: system menu; $mod+c: Countdown (see Custom Utilities).
      # $mod+Shift+q: kill the focused window (was $mod+q; moved so a stray
      #   plain-Q cannot destroy a window).
      bindsym Mod1+Tab exec ${pkgs.swayr}/bin/swayr switch-to-urgent-or-lru-window
      bindsym $mod+Tab exec ~/.local/bin/window-menu --away
      bindsym $mod+Shift+q kill

      # Wallpaper menu: Mod+Alt+w · windows: Mod+Tab (away) / Mod+Shift+Tab (regular) · next: Mod+Shift+w.
      # ~/Pictures/wallpapers (thumbnail grid, arrow keys to browse).
      bindsym $mod+Mod1+w exec ~/.local/bin/wallpaper-menu
      bindsym $mod+Shift+Tab exec ~/.local/bin/window-menu --normal
      bindsym $mod+Shift+w exec ~/.local/bin/wallpaper-set
      # $mod+y: toggle yazi popup (same pattern as scratchpad-terminal).
      bindsym $mod+y exec ~/.local/bin/yazi-open
      bindsym $mod+Shift+c exec ~/.local/bin/refresh-session
      # $mod+Shift+b: hide/show Waybar (SIGUSR1 — toggle, no restart).
      # $mod+b stays `splith`; this key is its Shift version.
      bindsym $mod+Shift+b exec ~/.local/bin/bar-toggle
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

      # 5 workspaces, không tên. Đây là cả bề mặt điều hướng — Waybar
      # ghim đúng 5 số này (xem waybar.nix).
      bindsym $mod+1 workspace number 1
      bindsym $mod+Shift+1 move container to workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+Shift+2 move container to workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+Shift+3 move container to workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+Shift+4 move container to workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+Shift+5 move container to workspace number 5
      # Switch to the previous/next workspace: $mod+[ / $mod+].
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
      bindsym $mod+minus move scratchpad
      # $mod+Shift+minus: hide ALL floating popups here (GoldenDict -> tray, rest -> scratchpad).
      # $mod+equal: show ONE hidden window — the one JUST stashed (LIFO, Sway keeps
      # its scratchpad list oldest-first); $mod+Shift+equal: show ALL, oldest first
      # so the freshest ends up on top. Show-only: neither ever hides back.
      # Minus hides, equal shows; pick one via $mod+Tab (also most-recent-first).
      bindsym $mod+Shift+minus [workspace=__focused__ floating app_id="(?i).*goldendict.*"] kill; [workspace=__focused__ floating] move container to scratchpad
      bindsym $mod+equal exec ~/.local/bin/popup-restore --one
      bindsym $mod+Shift+equal exec ~/.local/bin/popup-restore

      # Custom Utilities & Screenshot
      # $mod+p: daily utilities (Idle, Display, Wi-Fi, Bluetooth, Power Profile).
      bindsym $mod+p exec ~/.local/bin/utilities
      # $mod+c Countdown · $mod+Shift+p system actions (Lock, Suspend, Hibernate,
      # Reload/Exit Sway, Reboot, Poweroff) — same script, ordered safe -> destructive.
      # Chrome has no dedicated key — open via $mod+d (rofi) or click a link.
      bindsym $mod+c exec ~/.local/bin/countdown
      bindsym $mod+Shift+p exec ~/.local/bin/utilities --power
      # $mod+i removed. $mod+z/$mod+u/$mod/x LEFT EMPTY. Kill:
      # $mod+Shift+Tab then Shift+Delete, or $mod+Shift+q for the focused window.
      # quick-lang: t = clean English · Shift+t = Vietnamese · Ctrl+t = force
      # English fix. Prefix the selected text with [phi]/[sci]/[lit]/[cas] to set context.
      bindsym $mod+t exec ~/.local/bin/quick-lang vi-en
      bindsym $mod+Shift+t exec ~/.local/bin/quick-lang en-vi
      bindsym $mod+Ctrl+t exec ~/.local/bin/quick-lang fix
      # dict-toggle: toggle the GoldenDict float; closing = hide to tray
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

      # swayidle (systemd): lock at 300s -> screen off at 310s -> suspend at 900s on battery.
      # While a Countdown session runs -> countdown-engine stops this service, then starts it again.
    '';
  };

  # The window menu no longer uses swayr's own menu ($mod+Tab / $mod+Shift+Tab
  # now run `window-menu`), so the swayr config file + the swayr-rofi-menu
  # wrapper were dropped as well. Do not declare `xdg.configFile."swayr/config.toml"`
  # either: Home Manager cleans up files it used to manage on switch. Note: do NOT use
  # `source = null` — the option requires an absolute path; null fails eval.
  # swayrd still runs for Alt+Tab (jump to urgent / LRU window).

  # Record focus history for the whole Sway session; the target starts after SWAYSOCK is imported.
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

  # systemd for journald logging + auto-restart on crash + stops with the Sway session.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle manager for Wayland (lock → screen off → suspend)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      # Kill the OLD instance of ITSELF ("-" prefix = OK when there is nothing to kill).
      # Match specifically "swayidle -w timeout 300" so we do NOT kill Countdown's
      # lock-on-sleep instance (its cmdline starts with "-w before-sleep").
      ExecStartPre = "-${pkgs.procps}/bin/pkill -f 'swayidle -w timeout 300'";
      # PATH for commands swayidle spawns (swaymsg, systemctl, lock-screen).
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
