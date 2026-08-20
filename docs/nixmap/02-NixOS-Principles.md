# 02 — NixOS Principles

## The core idea

NixOS does not "install software" into a system the way Ubuntu does.
Instead, NixOS **builds the entire operating system** from a "recipe" (the flake).
Every rebuild produces a brand-new, complete system generation.

## What is a module

A NixOS module is a `.nix` file that declares **one part** of the operating system.
For example:

- `modules/nixos/core.nix` = the core: Nix settings, network, user, basic packages.
- `modules/nixos/desktop.nix` = the desktop: Sway, greetd, PipeWire, fonts, Fcitx5.
- `modules/nixos/development.nix` = development: VS Code, Python, GCC, Podman.
- `modules/nixos/laptop.nix` = laptop specifics: battery threshold, keyd, fwupd, zram (compressed swap).

## Anatomy of a module

```nix
{ pkgs, ... }:   # receive the arguments you need

{
  # Declare configuration here
  environment.systemPackages = with pkgs; [ git curl ];
  services.pipewire.enable = true;
}
```

## Why use modules

- **Separation of concerns**: each module owns one job. Easy to read, easy to change.
- **Reusability**: a new machine only imports the modules it already has.
- **No conflicts**: Nix merges all declarations together and resolves conflicts deterministically.

## Files inside modules/nixos/

| File | Main contents |
|------|---------------|
| `core.nix` | Nix settings, automatic GC, network, user account, base packages (git, curl, neovim, file...) |
| `desktop.nix` | Sway, greetd, PipeWire, Fcitx5 + Unikey, fonts, GPU acceleration, Polkit |
| `development.nix` | VS Code, Python + venv, GCC, CMake, Podman, Distrobox |
| `laptop.nix` | Battery threshold 80–85%, keyd remap, fwupd, zram (100% RAM, zstd) + swap tuning |

## Related

- [[01-Architecture-Overview]] — where modules sit in the repository
- [[03-Home-Manager]] — the difference between system and user
- [[06-Rebuild-Workflow]] — how to apply changes