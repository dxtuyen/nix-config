# 06 — Rebuild Workflow

## Why "rebuild" instead of "install"

When you change a `.nix` file you **don't** install the change — you **rebuild** the system.
Nix compares the desired state (your configuration) with the current one,
does the smallest possible change, and creates a new *generation*.

## The command

```bash
sudo nixos-rebuild switch --flake .#laptop
```

- `--flake .` — build from the flake in the current directory
- `.#laptop` — build the `nixosConfigurations.laptop` output
- `switch` — activate the new generation immediately

### Faster alternative: `nh`

```bash
nh os switch
```

`nh` (nix helper, enabled in `modules/nixos/core.nix`) wraps `nixos-rebuild`
and automatically uses the flake in the current directory.
It also deletes old generations automatically and shows a clearer diff.

## Applying user-only changes quickly

If you only changed something under `home/`, you can often get away with:

```bash
home-manager switch --flake .#doxuantuyen
```

(In this repo the home-manager flake output is exposed through the NixOS module,
so the usual way is still `nh os switch` / `nixos-rebuild switch`.)

## What happens on rebuild

1. Nix evaluates your entire configuration (flake.nix + hosts/ + modules/ + home/).
2. It computes the new system in `/nix/store` — ending in `system` symlink.
3. `switch` installs a new **generation** into the bootloader (systemd-boot).
4. Your old generation stays intact — rollback is always possible.

## Generations and rollback

- Each successful rebuild creates a new generation.
- List: `sudo nixos-rebuild list-generations`
- Boot into an old generation: pick it at the boot menu (systemd-boot).
- Rollback permanently: `sudo nixos-rebuild switch --rollback`
- Home Manager keeps its own generations: `home-manager generations`

## Cleanup

`modules/nixos/core.nix` already handles garbage collection automatically:

- `nix.gc.automatic = true` — GC weekly
- `nix.gc.options = "--delete-older-than 14d"` — keep only last 14 days
- `nix.optimise.automatic = true` — squash duplicate packages; weekly

## Setting up a brand-new machine

This repo is fully reproducible. On a new machine:

```bash
# Build + switch — zram (compressed RAM swap) is configured in laptop.nix,
# so no disk swap file/partition setup is needed at all.
nh os switch
```

No manual partitioning, no `mkswap`, no swap file creation: memory pressure is handled entirely by zram (100% of RAM, zstd) with tuned `vm.swappiness = 100`.

## Common mistakes

| Mistake | What actually happens |
|---------|----------------------|
| Editing files but not rebuilding | Nothing applies |
| Rebuilding with a different host name | Wrong configuration or error |
| Running `nixos-rebuild` without `sudo` | Permission error |
| Forgetting to `git add` new files | Flake error: path not found in tree |

## Related

- [[01-Architecture-Overview]] — what gets built
- [[02-NixOS-Principles]] — modules, generations, the store
- [[07-Glossary]] — flake, generation, nixpkgs