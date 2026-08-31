{
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
    networkmanager = {
      enable = true;
      # Dùng systemd-resolved làm DNS backend: có cache + fallback DNS tự động
      # (Cloudflare/Google) khi DNS router không trả lời. Trước đây resolv.conf
      # chỉ trỏ duy nhất vào router → router DNS "đứng hình" là mọi lookup fail
      # và phải tắt máy bật lại mới hết.
      dns = "systemd-resolved";
    };
    firewall.enable = true;
  };
  services.resolved.enable = true;
  programs.nh = {
    enable = true;
    # Cho `nh os switch` / `nh clean` biết flake mặc định mà không cần gõ path
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
}
