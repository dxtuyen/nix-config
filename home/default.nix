{ pkgs, userName, ... }:

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";
  };

  imports = [
    ./packages.nix
    ./gtk.nix
    ./sway.nix
    ./waybar.nix
    ./mako.nix
    ./fcitx5.nix
    ./scripts.nix
  ];

  programs.home-manager.enable = true;
}
