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
    extraSpecialArgs = { inherit userName; };
    users.${userName} = import ../../home;
  };

  system.stateVersion = "26.05";

  # Cấu hình XDG Desktop Portal cho Sway / wlroots.
  # LƯU Ý: ~1 giây khởi động đầu của Ghostty là BÌNH THƯỜNG (GTK4/Adwaita
  # khởi tạo nặng), không phải lỗi portal. Giữ wlr cho Chrome screen share.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [ "gtk" ];
      sway.default = lib.mkForce [
        "wlr"
        "gtk"
      ];
    };
  };
}
