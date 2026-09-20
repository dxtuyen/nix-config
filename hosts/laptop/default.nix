{
  inputs,
  userName,
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

  # Home-manager cấu hình tập trung tại đây.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup"; # đè file cũ thành *.backup thay vì lỗi build
    extraSpecialArgs = { inherit inputs userName; };
    users.${userName} = import ../../home;
  };

  system.stateVersion = "26.05";
}
