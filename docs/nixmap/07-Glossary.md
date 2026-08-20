# 07 — Glossary

## Nix core

| Term | Meaning |
|------|---------|
| **Nix** | The package manager + language. Everything in this repo is Nix expressions |
| **nixpkgs** | The central package repository (a flake input, pinned to `nixos-26.05`) |
| **Flake** | A self-contained Nix project with inputs and outputs. The repo root `flake.nix` is one |
| **Store** | `/nix/store` — every package/build lives here, content-addressed |
| **Generation** | A complete snapshot of the system. Every rebuild creates one |
| **GC** | Garbage collection — deletes unused store paths to reclaim space |
| **Derivation** | The build instruction Nix computes for a package |

## NixOS concepts

| Term | Meaning |
|------|---------|
| **NixOS module** | A `.nix` file declaring one part of the OS (`modules/nixos/*.nix`) |
| **nixos-rebuild** | The command that builds + switches the system (`switch`, `boot`, `test`, `dry-run`) |
| **systemd-boot** | The bootloader configured in `core.nix` — picks generations at boot |
| **Generation** | A named snapshot of system state; selectable at the boot menu |
| **allowUnfree** | `nixpkgs.config.allowUnfree = true` — permits non-free packages (Chrome, etc.) |
| **nh** | Nix helper (`programs.nh.enable`) — a friendlier wrapper around `nixos-rebuild` |
| **State version** | `system.stateVersion = "26.05"` — pins backward-compatible defaults |
| **Swap file** | `/swapfile` (8G, priority -2) declared in `laptop.nix` — lets the system hibernate safely, used only after zram is exhausted. Created once per machine via `sudo nix run .#setup-swapfile` |
| **zram** | Compressed swap **inside RAM** (3.7G, zstd, priority 10) — faster than SSD swap and reduces SSD wear. Ubuntu/Fedora/ChromeOS enable it by default |
| **Hibernate** | `systemctl hibernate` — saves RAM to swap and powers off; resume restores exactly |
| **Resume device** | `boot.resumeDevice = "/swapfile"` — tells the kernel where to find the hibernation image |

## Wayland / desktop

| Term | Meaning |
|------|---------|
| **Wayland** | Modern display protocol (replaces X11) |
| **Sway** | Tiling window manager for Wayland (`home/sway.nix`) |
| **Wlroots** | The low-level compositor library Sway uses |
| **Greetd** | Lightweight display manager used in `desktop.nix` (with `tuigreet`) |
| **Tuigreet** | TUI greetd greeter — the login screen |
| **PipeWire** | Audio/video server (Wayland-native, replaces PulseAudio) |
| **Waybar** | Sway's status bar strip |
| **Mako** | Sway's notification daemon |
| **Rofi** | Application launcher + window switcher |
| **Foot** | The default terminal (Tokyo Night theme) |
| **Slurp / grim** | Region selector + screen recorder; used with `grim` for screenshots |
| **wl-clipboard** | Clipboard (`wl-copy` / `wl-paste`) for Wayland |
| **wlsunset** | Blue-light filter / screen temperature control |

## Home Manager

| Term | Meaning |
|------|---------|
| **Home Manager** | User-level declarative config tool — manages `~/.config`, `~/.local/bin`, packages |
| **home.packages** | User packages declared in `home/packages.nix` |
| **xdg.enable** | Base switch enabling `xdg.configFile`, `xdg.desktopEntries`, `xdg.mimeApps` |
| **desktop entry** | A `.desktop` file telling menus/file managers what an app is (`xdg.desktopEntries`) |
| **MIME** | File-type metadata — used to decide which app opens which file (`xdg.mimeApps`) |
| **AppImage** | A self-contained Linux application archive (e.g., RemNote); run with `appimage-run` |

## Applications & scripts mentioned in this repo

| Name | What it does | Defined in |
|------|--------------|------------|
| `lock-screen` | Locks the screen (swaylock + auto power-off) | `home/scripts.nix` |
| `cycle-wallpaper` | Changes wallpaper by time of day (06:00 bright, 18:00 night) | `home/scripts.nix` |
| `quick-lang` | Translate selected text (VI→EN / EN→VI) via `trans` and copy result | `home/scripts.nix` |
| `toggle-touchpad`, `toggle-wlsunset` | Toggle devices/modes with notifications | `home/scripts.nix` |
| `cycle-power-profile` | Cycle `power-saver → balanced → performance` | `home/scripts.nix` |
| `media-notify` | OSD notifications for volume / brightness keys | `home/scripts.nix` |
| `open-study-apps` | Open RemNote + Calibre together | `home/scripts.nix` |
| `update-remnote` | Update RemNote AppImage from `~/Downloads` | `home/remnote.nix` |
| `refresh-session` | Reload Sway + Wallpaper + wlsunset | `home/scripts.nix` |

## Related

- [[01-Architecture-Overview]] — how the concepts fit together
- [[02-NixOS-Principles]] — module theory
- [[06-Rebuild-Workflow]] — commands that make all of this real