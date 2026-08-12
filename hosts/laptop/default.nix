{ inputs, userName, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/laptop.nix
  ];

  networking.hostName = "laptop";

  home-manager = {
    extraSpecialArgs = { inherit userName; };
    users.${userName} = import ../../home;
  };

  # Do not change after the initial installation; it controls compatibility
  # defaults, not the release to which packages are upgraded.
  system.stateVersion = "26.05";
}
