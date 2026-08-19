# 05 — Thunar Integration (A Real Story)

## The problem

On a tiling window manager, the file manager's **"open terminal here"** button
only works if the system knows which terminal to launch. Thunar (via `libexo`)
reads a file called `helpers.rc` to decide. On NixOS nothing sets this by default,
so the button silently does nothing — or opens the wrong terminal.

## The three-step fix in home/thunar.nix

### Step 1 — Tell libexo that Foot is the terminal

```nix
xdg.configFile."xfce4/helpers.rc" = {
  text = ''
    TerminalEmulator=foot
  '';
};
```

This writes `~/.config/xfce4/helpers.rc` so every XFCE helper
(including Thunar) uses `foot` whenever it needs a terminal.

### Step 2 — Create a dedicated "Neovim" desktop entry

Thunar's "Open with..." menu can show a custom entry that opens text files
directly in Neovim running inside Foot:

```nix
xdg.desktopEntries.nvim = {
  name = "Neovim (Foot)";
  comment = "Open in neovim inside foot";
  icon = "nvim";
  exec = "foot -e nvim %F";
  terminal = false;
  type = "Application";
  categories = [ "Utility" "TextEditor" "Development" ];
  mimeType = [ "text/plain" "text/x-c" "application/x-shellscript" ... ];
};
```

Key detail: `terminal = false` because the terminal is **already** part of the command
(`foot -e nvim`). If `terminal` were `true`, Thunar would wrap the command in
another terminal first — doubling it.

### 3 — Make it the default for plain text files

```nix
xdg.mimeApps.defaultApplications."text/plain" = [ "nvim.desktop" ];
```

Now double-clicking a `.txt` (or C/C++, shell, TeX...) file in Thunar opens it in
Neovim inside Foot — no extra terminal wrapper.

## Why this needs xdg.enable

All of the above (`xdg.configFile`, `xdg.desktopEntries`, `xdg.mimeApps`)
only work because `xdg.enable = true` is switched on **once** at the entry point
`home/default.nix`. This keeps the foundation in one place while modules
like `thunar.nix` stay declarative and small.

## Takeaway

A simple "Open Terminal Here" button is actually a chain of three XDG mechanisms:
`helpers.rc` (terminal emulator registration), `desktopEntries` (app definition),
and `mimeApps` (default application routing). Home Manager makes all three declarative.

## Related

- [[03-Home-Manager]] — where Thunar config lives
- [[04-Sway-Desktop]] — the desktop these entries appear in
- [[07-Glossary]] — XDG, .desktop, MIME