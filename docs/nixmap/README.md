# Nix-Config Map — Start Here

An Obsidian vault that explains the entire structure of the `nix-config` repository.
Open the `nix-config/docs/nixmap/` folder as a vault in Obsidian.

## How to use

Each Markdown file below explains one part of the repository.
You do not need to read them in order — follow the `[[bracketed links]]` to explore.
Every note has the same shape: **WHAT it is + WHY it works this way + WHERE it lives**.

## Table of contents

| # | File | Contents |
|---|------|----------|
| 00 | [[README]] | You are here |
| 01 | [[01-Architecture-Overview]] | What the whole repository revolves around |
| 02 | [[02-NixOS-Principles]] | What a NixOS module is and how it combines into an OS |
| 03 | [[03-Home-Manager]] | User configuration: apps, scripts, desktop |
| 04 | [[04-Sway-Desktop]] | Sway, Waybar, Rofi, Mako, Foot |
| 05 | [[05-Thunar-Integration]] | Real-life story: integrating Thunar with Foot and Neovim |
| 06 | [[06-Rebuild-Workflow]] | Rebuild commands, rollback, `nixos-rebuild` |
| 07 | [[07-Glossary]] | Simple glossary |

## Where to start

If you want to go from zero to full understanding:

1. [[01-Architecture-Overview]] — understand the map
2. [[02-NixOS-Principles]] — understand how the OS is built
3. [[03-Home-Manager]] — understand user-level config
4. [[04-Sway-Desktop]] — understand the UI
5. [[05-Thunar-Integration]] — see a real application
6. [[07-Glossary]] — look up terms any time

## Never forget

- Changes only take effect after `sudo nixos-rebuild switch --flake .#laptop` or `nh os switch`.
- `nh os switch` is a convenient, faster alternative to `nixos-rebuild`.
- The day the system is "finished" is the day this map stops being a map
  and starts being a to-do list. Keep it alive.