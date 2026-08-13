{ pkgs, userName, ... }:

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";
    sessionPath = [ "$HOME/.local/bin" ];
  };

  imports = [
    ./packages.nix
    ./gtk.nix
    ./sway.nix
    ./waybar.nix
    ./mako.nix
    ./fcitx5.nix
    ./scripts.nix
    ./remnote.nix
  ];

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
