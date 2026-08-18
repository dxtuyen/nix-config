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
  ];

  networking.hostName = "laptop";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs userName; };
    users.${userName} = import ../../home;
  };

  system.stateVersion = "26.05";

  # Cấu hình XDG Desktop Portal cho Sway / wlroots
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [ "gtk" ];
      sway = {
        default = lib.mkForce [
          "wlr"
          "gtk"
        ];
      };
    };
  };
}