{ ... }:

# Đăng ký Alacritty làm terminal mặc định cho Thunar + entry Neovim mở trong
# Alacritty. Thùng rác cần GVFS (`services.gvfs.enable` ở desktop.nix).

{
  # libexo dùng Alacritty làm terminal.
  xdg.configFile."xfce4/helpers.rc" = {
    text = ''
      TerminalEmulator=alacritty
    '';
  };

  # Entry Neovim mở trực tiếp trong Alacritty (không qua exo helper).
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

  # Mở text/plain bằng entry Neovim trên.
  xdg.mimeApps.defaultApplications."text/plain" = [ "nvim.desktop" ];
}
