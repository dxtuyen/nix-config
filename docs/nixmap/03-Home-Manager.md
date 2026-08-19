# 03 — Home Manager

## What is Home Manager

Home Manager is a Nix tool that manages **user-level configuration**.
While NixOS manages the system (needs root), Home Manager manages
`~/.config`, `~/.local/bin`, and user-installed packages.

## Where it sits in the repository

- `home/default.nix` = the entry point. It imports every file inside `home/`.
- Each file inside `home/` = one Home Manager module.
- The home-manager NixOS module is enabled in `modules/nixos/core.nix`
  (`useGlobalPkgs`, `useUserPackages`, `backupFileExtension`),
  and the user's home config is wired in `hosts/laptop/default.nix`
  via `home-manager.users.${userName} = import ../../home;`.

## Files inside home/

| File | Purpose |
|------|---------|
| `default.nix` | Entry point; imports all modules, enables `xdg`, adds `~/.local/bin` to PATH via bash |
| `packages.nix` | User packages via `home.packages` (rofi, thunar, obsidian, anki...) |
| `foot.nix` | Foot terminal (Tokyo Night theme) |
| `gtk.nix` | GTK theme, icon theme, cursor, dark mode |
| `sway.nix` | Sway window manager configuration |
| `waybar.nix` | Waybar status bar |
| `mako.nix` | Mako notification daemon |
| `fcitx5.nix` | Vietnamese input method (Fcitx5 + Unikey) |
| `scripts.nix` | Hand-written scripts installed into `~/.local/bin` |
| `remnote.nix` | RemNote AppImage integration |
| `thunar.nix` | Register Foot as Thunar's default terminal + Neovim entry |

## Why split this way

- **One file per topic**: easy to find, easy to change.
- **Centralised imports**: `default.nix` is the only file that imports. You always know what is active.
- **Reusability**: a new machine only has to import `home/`.
- **Clean separation of powers**: `default.nix` owns the foundation (XDG, PATH);
  child modules (remnote, thunar...) only declare content.

## Why `xdg.enable` lives in default.nix

`xdg.enable = true` enables XDG base directory support and is the single switch that
turns on `xdg.configFile`, `xdg.desktopEntries` and `xdg.mimeApps` in child modules.
It lives at the entry point so the foundation is switched on **exactly once**,
and `remnote.nix`, `thunar.nix`, `fcitx5.nix` etc. never have to enable it themselves.

## Why PATH lives in bash, not sessionPath

`~/.local/bin` (where scripts like `update-remnote`, `lock-screen`, `quick-lang` land)
is added to PATH via `programs.bash.initExtra`. NixOS doesn't create `~/.bashrc` for you,
so `programs.bash.enable` is the single place that writes it.

## Related

- [[01-Architecture-Overview]] — where `home/` sits in the repo
- [[02-NixOS-Principles]] — the difference between system and user
- [[04-Sway-Desktop]] — the UI built on top of these modules
- [[05-Thunar-Integration]] — a real example that uses `xdg`