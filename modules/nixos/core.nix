{
  lib,
  pkgs,
  userName,
  ...
}:

{
  # Run garbage collection weekly and keep the last seven days.
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot = {
    enable = true;
    # Keep at most 10 boot entries.
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    networkmanager = {
      enable = true;
      # Use systemd-resolved for DNS caching and fallback.
      dns = "systemd-resolved";
    };
    firewall.enable = true;
  };
  services.resolved.enable = true;
  # Disable nscd to avoid stale NSS cache entries.
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [ ];
  programs.nh = {
    enable = true;
    # nh uses this flake by default.
    flake = "/home/${userName}/nix-config";
  };

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
      "kvm"
    ];
  };

  # Keep SSH keys unlocked for the login session (see docs/03).
  programs.ssh.startAgent = true;

  # Shared packages for systems importing core.nix.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    zip
    htop
    file # Inspect file types.
  ];
}
