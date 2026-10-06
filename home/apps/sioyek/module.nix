{ userName, ... }:

{
  # Each new file = a separate window (still 1 process); new windows appear on the
  # focused workspace via the for_window rule in home/config/sway.nix.
  xdg.configFile."sioyek/prefs_user.config".text = ''
    should_launch_new_window 1
  '';

  # All PDF open paths go through sioyek-open (apps cannot focus themselves on Wayland).
  xdg.desktopEntries.sioyek = {
    type = "Application";
    name = "Sioyek";
    comment = "PDF viewer for reading research papers and technical books";
    # Absolute path (the sway session has no ~/.local/bin in PATH).
    exec = "/home/${userName}/.local/bin/sioyek-open %f";
    icon = "sioyek-icon-linux";
    categories = [
      "Development"
      "Viewer"
    ];
    terminal = false;
    startupNotify = true;
    settings = {
      StartupWMClass = "sioyek";
      # Declare only `settings`, NOT `mimeType` (the module translates it into
      # `extraConfig` — the option was removed in HM 26.05 -> no file is generated).
      MimeType = "application/pdf;";
    };
  };
}
