{
  pkgs,
  userName,
  ...
}:

{
  # gc hàng tuần: xóa generation cũ hơn 7 ngày. Xem lần chạy gần nhất:
  # journalctl -u nix-gc.service. Xóa tay: sudo nix-collect-garbage -d.
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
    # Giữ tối đa 10 entry trong menu boot.
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    networkmanager = {
      enable = true;
      # systemd-resolved có cache + fallback DNS khi DNS router lỗi.
      dns = "systemd-resolved";
    };
    firewall.enable = true;
  };
  services.resolved.enable = true;
  programs.nh = {
    enable = true;
    # `nh os switch` tự biết flake mặc định.
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

  # ssh-agent giữ passphrase SSH trong phiên đăng nhập (docs/03 Bước 10).
  programs.ssh.startAgent = true;

  # Gói dùng chung cho mọi máy import core.nix.
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    zip
    neovim
    htop
    file # xem nhanh định dạng file
  ];
}
