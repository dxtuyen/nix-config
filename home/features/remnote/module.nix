{ pkgs, config, ... }:

# RemNote AppImage: an out-of-Nix file in ~/Apps/RemNote/ (not embedded in the build).
# Usage: download the file to ~/Downloads then run `setup-remnote`.

{
  # Tools to run AppImages + extract icons: appimage-run · squashfsTools (unsquashfs)
  # · desktop-file-utils (update-desktop-database, Rofi/GIO read the app list).
  home.packages = with pkgs; [
    appimage-run
    squashfsTools
    desktop-file-utils
  ];

  # Desktop entry for Rofi. `exec` uses an ABSOLUTE PATH: Rofi drops the
  # entry when it cannot find the binary in PATH.
  xdg.desktopEntries.remnote = {
    name = "RemNote";
    comment = "RemNote note-taking app";
    exec = "${pkgs.appimage-run}/bin/appimage-run ${config.home.homeDirectory}/Apps/RemNote/RemNote.AppImage";

    # Icon extracted from the AppImage by `setup-remnote`; use an ABSOLUTE path so
    # it does not depend on the GTK icon theme/cache.
    icon = "${config.home.homeDirectory}/.local/share/icons/hicolor/512x512/apps/remnote.png";

    terminal = false;
    type = "Application";

    categories = [
      "Office"
      "Utility"
    ];

    # Taken from the original .desktop inside the AppImage: the window maps to the right icon/app when grouping.
    settings.StartupWMClass = "RemNote";
  };
}
