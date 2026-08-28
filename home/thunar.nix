{ ... }:

# Dang ky Alacritty lam terminal mac dinh cho Thunar va tao entry Neovim
# mo truc tiep trong Alacritty (khong phu thuoc Terminal=true cua nvim.desktop).
#
# Luu y: goi `thunar` duoc cai qua home/packages.nix. Thung rac (Move to
# Trash) can GVFS daemon, duoc bat o NixOS level `services.gvfs.enable`
# trong modules/nixos/desktop.nix (thieu GVFS thi Thunar xoa thang, khong
# co Thung rac).

{
  # 1. Ghi ~/.config/xfce4/helpers.rc de libexo biet terminal la alacritty
  xdg.configFile."xfce4/helpers.rc" = {
    text = ''
      TerminalEmulator=alacritty
    '';
  };

  # 2. Tao desktop entry "Neovim" rieng: Exec = alacritty -e nvim,
  # Terminal = false de Thunar mo truc tiep khong qua exo helper.
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    comment = "Open in neovim inside alacritty";
    icon = "nvim";
    exec = "alacritty -e nvim %F";
    terminal = false;
    type = "Application";
    categories = [
      "Utility"
      "TextEditor"
      "Development"
    ];
    mimeType = [
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
    ];
  };

  # 3. Dat mac dinh text/plain cho entry Neovim (Alacritty)
  xdg.mimeApps.defaultApplications."text/plain" = [ "nvim.desktop" ];
}
