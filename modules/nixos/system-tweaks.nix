{ ... }:

{
  # Diệt tiến trình ngốn RAM trước khi desktop treo (ngưỡng còn 5% RAM).
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    enableNotifications = true;
  };
  # Dùng earlyoom làm cơ chế OOM chính để tránh chạy đồng thời hai daemon.
  systemd.oomd.enable = false;

  # TRIM hàng tuần cho SSD/NVMe.
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Chạy binary biên dịch sẵn (VS Code server, JetBrains...) không cần patch.
  programs.nix-ld.enable = true;
}
