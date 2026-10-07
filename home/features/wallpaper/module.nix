{ pkgs, ... }:

{
  # Create the wallpaper data directories outside the repo when Home Manager activates.
  home.activation.wallpaperDirs = ''
    mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots"
  '';

  # The awww daemon rides along with the Sway session; wallpaper-set waits for it to be ready.
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon (swww fork)";
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
