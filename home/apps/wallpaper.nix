{ pkgs, ... }:

{
  # Tạo thư mục dữ liệu ảnh ngoài repo khi Home Manager kích hoạt.
  home.activation.wallpaperDirs = ''
    mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots"
  '';

  # Daemon awww đi cùng phiên Sway; wallpaper-set chờ daemon sẵn sàng.
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon (fork của swww)";
      After = [ "sway-session.target" ];
      PartOf = [ "sway-session.target" ];
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "sway-session.target" ];
  };
}
