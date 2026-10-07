# 🖥️ NixOS Config — Doxuan Tuyen

**NixOS + Home-Manager** configuration for a personal laptop, running **Sway** (Wayland) with a consistent **Catppuccin Mocha** theme (GTK uses the neutral adw-gtk3-dark).

| | |
|---|---|
| 🌐 System | NixOS unstable (x86_64-linux, rolling release) |
| 🪟 Desktop | Sway + Waybar + Mako (notifications) |
| 💻 Terminal | Foot + Starship |
| 🖼️ Viewing photos / video | imv (images) • mpv (video) • foliate (e-books) • sioyek (PDF) |
| ⌨️ Input method | Fcitx5 + Bamboo |
| 💾 Hibernate | 10G swap — saves state on power-off |

---

## 🚀 Rebuild & Update

Enable the automatic check before every push (run once per clone):

```bash
git config core.hooksPath .githooks
```

The hook checks the exact commit being pushed with the same two CI commands: `nix fmt -- --check` and `nix flake check --no-build`. If formatting fails, run `nix fmt`, review the changes, commit and push again.

```bash
cd nix-config
git pull --rebase        # fetch latest code
nix fmt                  # format *.nix (nixfmt)
sudo nixos-rebuild switch --flake .#laptop   # or: nh os switch
# Once the shell alias is updated: nswitch (cds into the repo from anywhere and rebuilds by hostname)
```

> A single command updates **both NixOS and home-manager** (home-manager is attached via `home-manager.nixosModules` in `hosts/laptop/default.nix`).

---

## 🗂️ Directory Structure

```
nix-config/
├── flake.nix                    # Entry point: nixpkgs + home-manager, "laptop" build target
├── hosts/laptop/                # Machine-specific configuration
│   ├── default.nix              # Imports modules + attaches home-manager
│   └── hardware-configuration.nix  # Auto-generated at install time
├── home/                        # Home Manager (user-level)
│   ├── default.nix              # User setup + imports config, apps and scripts
│   ├── config/                  # Desktop config, user packages, default apps
│   ├── apps/                    # Per-app modules; related scripts live with each app
│   │   ├── countdown/           # Timer, engine, sleep watcher and user services
│   │   ├── remnote/             # AppImage setup and desktop entry
│   │   ├── sioyek/              # PDF viewer and open wrappers
│   │   ├── wallpaper/           # Wallpaper daemon, picker and helpers
│   │   └── yazi/                # File manager config and open helper
│   └── scripts/                 # Shared user commands grouped by responsibility
│       ├── desktop/             # Sway, screenshot, popup and night-light helpers
│       ├── media/               # Volume and brightness notifications
│       ├── session/             # Locking, idle suspend and session refresh
│       ├── system/              # VM and power-profile helpers
│       └── utilities/           # Language, dictionary, cleanup and daily menu
├── modules/nixos/               # NixOS modules (system-level)
│   ├── core.nix                 # Foundation: Nix/flake, boot, network, user
│   ├── desktop.nix              # Sway/greetd, PipeWire, Fcitx5, fonts
│   ├── development.nix          # VS Code, Python, GCC, podman…
│   ├── laptop.nix               # Hibernate (resume=/dev/disk/by-label/swap), zram, keyd, battery threshold — swap matched by label
│   └── system-tweaks.nix        # earlyoom, fstrim, nix-ld
├── docs/                        # 📚 Docs (see below)
└── lockscreen/                  # 🖼️ Lock screen (swaylock) and default wallpaper image
```

> 🖼️ **Wallpapers are NOT in the repo**: `~/Pictures/wallpapers/` is your own folder — just `cp`/`rm`, no rebuild needed.

---

## 📚 Documentation

Start from the hub [`docs/README.md`](docs/README.md):

| Doc | Contents |
|---|---|
| [Fresh install from scratch](docs/03-Cai-May-Moi.md) | USB → partitioning → install → hibernate → **Step 10: Git & SSH** |
| [VM practice](docs/06-Luyen-Tap-VM.md) | Practice installing with a virtual machine (QEMU/KVM) |

---

## 💡 Highlights

| Feature | Description |
|---|---|
| **ZRAM** | zstd-compressed swap at 50% of RAM — faster than SSD, less disk wear |
| **Hibernate** | `systemctl hibernate` — writes all of RAM into the 10G swap then powers off; powering on restores the exact state |
| **Battery threshold** | Charging limited to 85–90% |
| **keyd** | Caps Lock = Ctrl (hold) / Esc (tap) |
| **Power profiles** | battery-saver / balanced / performance |
| **earlyoom** | Kills RAM-hungry processes before the desktop freezes |
| **fwupd** | Firmware updates |
