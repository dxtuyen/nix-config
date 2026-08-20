# 01 — Architecture Overview

## What this repository is for

This repository **describes your entire operating system as code**.
It is not about "installing software" — it is about **declaring what the OS should look like**,
then letting Nix build exactly that.

## The two main layers

| Layer | Folder | Managed by | Examples |
|-------|--------|------------|----------|
| Operating system | `modules/nixos/` | NixOS | Sway, greetd, PipeWire, fonts, user account |
| User | `home/` | Home Manager | Sway config, Waybar, Foot, scripts |

## What this means

- `modules/nixos/` = things that need **root** to install: window manager, audio, display manager, user accounts.
- `home/` = things that belong to the **user**: app configurations, key bindings, personal scripts, themes.

## Where everything plugs in

- `flake.nix` = the entry point. It declares which nixpkgs + home-manager versions to use, and which host to build.
- `hosts/laptop/default.nix` = the configuration for the machine called "laptop". It imports the shared modules.
- `home/default.nix` = the entry point of Home Manager. It imports every file inside `home/`.

## The NixOS modules (`modules/nixos/`)

| Module | Responsibility |
|--------|----------------|
| `core.nix` | Shared base for every machine: Nix daemon, boot, network, users, system packages |
| `desktop.nix` | Display server (Sway), GPU, audio (PipeWire), power, bluetooth, XDG portal, Fcitx5, fonts |
| `development.nix` | Dev tools (VS Code, Python, GCC...) + Podman |
| `laptop.nix` | Laptop-specific: ZRAM, keyd, battery threshold, fwupd |
| `system-tweaks.nix` | System performance & maintenance: earlyoom, fstrim, nix-ld |

## Why split it this way

- **Reusability**: `core.nix` is shared by every machine. A new machine only imports the modules it needs.
- **Maintainability**: edit one place, apply everywhere.
- **Clear boundaries**: it is obvious which parts require root and which parts belong to the user.

## Related

- [[02-NixOS-Principles]] — dive deeper into modules
- [[03-Home-Manager]] — dive deeper into user config
- [[06-Rebuild-Workflow]] — how to apply changes