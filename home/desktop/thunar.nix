# Thunar for graphical file work. The GIO trash is already running thanks to
# `services.gvfs.enable` in modules/nixos/desktop.nix (soft delete via yazi's `d`),
# emptied daily at 03:00 by the user timer `trash-clean` — the trash lives outside
# the repo so it is not declared here.
#
# This module only does its real job: set the terminal for libexo (Thunar reads
# `TerminalEmulator` for the "Open Terminal Here" action — the default action of
# thunar-uca so no uca.xml is needed). Default apps by file type and the
# `nvim.desktop` entry for text live in `home/desktop/mimeapps.nix`.
{
  xdg.configFile."xfce4/helpers.rc".text = "TerminalEmulator=foot\n";
}
