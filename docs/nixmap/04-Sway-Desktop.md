# 04 — Sway Desktop

## What is Sway

Sway is a **window manager** that runs on Wayland.
It manages: windows, workspaces, key bindings, wallpaper, and idle behaviour.

## Where everything is configured

- `home/sway.nix` = the Sway configuration (key bindings, workspaces, rules, idle).
- `home/waybar.nix` = the status bar (top bar).
- `home/foot.nix` = the default terminal.
- `home/mako.nix` = the notification daemon.
- `home/gtk.nix` = theme, icons, cursor.
- `home/packages.nix` = user-space tools Sway depends on (rofi, swaylock, swayidle, grim, slurp, wl-clipboard, wlsunset...).
- `home/scripts.nix` = custom scripts bound to keys (lock-screen, cycle-wallpaper, quick-lang...).

## How sway.nix is structured

```nix
wayland.windowManager.sway = {
  enable = true;
  package = null;        # use the Sway provided by the NixOS module
  config = null;         # full control via raw string
  systemd.enable = true; # manages the session with systemd
  extraConfig = ''
    # key bindings, workspaces, rules...
  '';
};
```

## Main key bindings

| Key | Function |
|-----|----------|
| `mod+Return` | Open terminal (foot) |
| `mod+d` | Open launcher (rofi -show drun) |
| `mod+Tab` | Rofi window switcher |
| `mod+Shift+q` | Close window |
| `mod+1..4` | Switch to named workspaces (study, AI, code, others) |
| `mod+Shift+1..4` | Move window to a named workspace |
| `mod+f` | Toggle fullscreen |
| `mod+space` | Toggle focus mode (floating/tiling) |
| `mod+Shift+space` | Toggle floating |
| `mod+r` | Enter resize mode |
| `mod+Shift+s` | Open study apps (RemNote + Calibre) |
| `mod+Shift+o` | Lock screen |
| `mod+Shift+p` | Suspend |
| `mod+End` | Power off |
| `mod+Control+End` | Reboot |
| `mod+Control+p` | Cycle power profile |
| `mod+t` | Translate VI → EN (quick-lang) |
| `mod+Shift+t` | Translate EN → VI (quick-lang) |
| `mod+Control+t` | Toggle touchpad |
| `Print` | Screenshot selection to clipboard |
| `Mod1+Print` | Screenshot whole screen to clipboard |
| `XF86Audio*` / `XF86MonBrightness*` | Media & brightness keys with OSD notifications |

## Why Sway

- **Lightweight**: not a full desktop (GNOME/KDE), just the windows.
- **Wayland-native**: modern, smooth, more secure.
- **Text-based configuration**: easy to version-control and reuse.

## Environment & session integration

- `exec dbus-update-activation-environment` synchronises `WAYLAND_DISPLAY`, `XDG_CURRENT_DESKTOP`, `SWAYSOCK`, `XMODIFIERS`, `QT_IM_MODULE`, `FOOT_COLOR_SCHEME` into systemd + DBus.
- `exec systemctl --user start sway-session.target` starts everything that wants Wayland.
- `exec systemctl --user import-environment` makes the systemd user session aware of the Sway environment.
- `seat * hide_cursor 7000` → the cursor hides after 7 seconds of inactivity.

## Related

- [[01-Architecture-Overview]] — where Sway sits in the repo
- [[03-Home-Manager]] — Sway is user config
- [[05-Thunar-Integration]] — how desktop entries interact with Thunar