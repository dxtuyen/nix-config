{
  inputs,
  userName,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/development.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/system-tweaks.nix
  ];

  networking.hostName = "laptop";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs userName; };
    users.${userName} = import ../../home;
  };

  system.stateVersion = "26.05";
}
