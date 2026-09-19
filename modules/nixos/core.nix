{
  pkgs,
  userName,
  ...
}:

{
  # Dọn dẹp theo chuẩn cộng đồng NixOS:
  # - gc hàng tuần: xoá các generation cũ hơn 7 ngày (cả hệ thống lẫn user) +
  #   store path không còn dùng. Giữ 1 tuần để còn bản dự phòng quay lại khi
  #   bản mới hỏng. Xem lần chạy gần nhất: journalctl -u nix-gc.service
  # - configurationLimit (dưới cuối file): chặn số entry menu boot lúc rebuild
  # Xoá tay MỌI generation cũ bất kỳ lúc nào: sudo nix-collect-garbage -d
  # (hoặc `nh clean all` — nh đã bật trong file này)
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
    # Chỉ giữ tối đa 10 entry mới nhất trong menu boot (mặc định không giới hạn
    # → menu phình to sau nhiều lần rebuild). Kết hợp gc 7d ở trên: mỗi lần
    # rebuild, systemd-boot tự xoá entry cũ vượt ngưỡng trong /boot luôn —
    # không phải dọn tay.
    configurationLimit = 10;
  };
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

  # ssh-agent: giữ passphrase của SSH key trong phiên đăng nhập
  # → không phải gõ lại passphrase mỗi lần git push/pull qua SSH
  # (docs/03 Bước 10).
  programs.ssh.startAgent = true;

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
