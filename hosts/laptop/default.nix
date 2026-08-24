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

  # Cấu hình home-manager gom về MỘT nơi duy nhất là file host này.
  # (Trước đây useGlobalPkgs/useUserPackages bị khai trùng trong core.nix.)
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup"; # đè file cũ thành *.backup thay vì lỗi build
    extraSpecialArgs = { inherit inputs userName; };
    users.${userName} = import ../../home;
  };

  system.stateVersion = "26.05";
}
