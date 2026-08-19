{ ... }:

# Dang ky Foot lam terminal mac dinh cho Thunar va tao entry Neovim
# mo truc tiep trong Foot (khong phu thuoc Terminal=true cua nvim.desktop).

{
  # 1. Ghi ~/.config/xfce4/helpers.rc de libexo biet terminal la foot
  xdg.configFile."xfce4/helpers.rc" = {
    text = ''
      TerminalEmulator=foot
    '';
  };

  # 2. Tao desktop entry "Neovim" rieng: Exec = foot -e nvim,
  # Terminal = false de Thunar mo truc tiep khong qua exo helper.
  xdg.desktopEntries.nvim = {
    name = "Neovim (Foot)";
    comment = "Open in neovim inside foot";
    icon = "nvim";
    exec = "foot -e nvim %F";
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

  # 3. Dat mac dinh text/plain cho entry Neovim (Foot)
  xdg.mimeApps.defaultApplications."text/plain" = [ "nvim.desktop" ];
}
