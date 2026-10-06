{ ... }:

{
  programs.helix = {
    enable = true;
    # Keep Neovim as the default editor while trying Helix with `hx`.
    defaultEditor = false;
  };
}
