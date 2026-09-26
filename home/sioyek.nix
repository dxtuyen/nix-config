{ userName, ... }:

{
  # Mỗi file mới = cửa sổ riêng (vẫn 1 process); cửa sổ mới hiện ở workspace
  # đang focus nhờ rule for_window trong home/sway.nix.
  xdg.configFile."sioyek/prefs_user.config".text = ''
    should_launch_new_window 1
  '';

  # Mọi đường mở PDF đi qua sioyek-open (tránh app không tự focus trên Wayland).
  xdg.desktopEntries.sioyek = {
    type = "Application";
    name = "Sioyek";
    comment = "PDF viewer for reading research papers and technical books";
    # Đường dẫn tuyệt đối (session sway không có ~/.local/bin trong PATH).
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
      # `mimeType` bị module xdg.desktopEntries dịch qua `extraConfig` — option
      # đã bị XOÁ ở Home-Manager 26.05 → entry này không được sinh file.
      # `settings` là option thay thế, vẫn sinh đúng dòng MimeType=.
      MimeType = "application/pdf;";
    };
  };
}
