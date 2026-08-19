{
  inputs,
  pkgs,
  userName,
  ...
}:

{
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };
  programs.nh.enable = true;

  time.timeZone = "Asia/Ho_Chi_Minh";
  services.timesyncd.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.${userName} = {
    isNormalUser = true;
    description = "Doxuan Tuyen";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # Gói hệ thống — áp dụng cho MỌI máy import core.nix
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    zip
    neovim
    htop
    file # Xác định dạng file bất kỳ (PDF, zip, ELF, script...)
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };
}
