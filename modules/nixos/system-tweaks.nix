{ ... }:

{
  # Early OOM killer — kills the worst memory hog before the kernel OOM killer
  # freezes the whole desktop. 5% free memory threshold with desktop notifications.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5; # kill when only 5% RAM is free
    enableNotifications = true; # desktop notifications via systemd
  };

  # Weekly TRIM for SSD/NVMe — prevents write performance degradation over time.
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # nix-ld — run standard, dynamically linked pre-compiled binaries
  # (e.g. VS Code server, JetBrains, proprietary tools) without patching.
  programs.nix-ld.enable = true;
}
