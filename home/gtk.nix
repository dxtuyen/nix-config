{ pkgs, ... }:

# Cursor + GTK theme (adw-gtk3-dark) + icon (Papirus-Dark).
#
# Hệ thống dùng Catppuccin Mocha cho mọi thứ TỰ VẼ (foot/sway/waybar/mako/
# starship/yazi). Riêng GTK dùng adw-gtk3-dark TRUNG TÍNH, vì:
#   • `catppuccin/gtk` upstream đã ARCHIVE (02/06/2024) — đông cứng, không
#     fix cho GTK/libadwaita mới. Còn `tokyonight-gtk-theme` thì đã bị XOÁ
#     khỏi nixpkgs (kéo gtk-engine-murrine/GTK2).
#   • adw-gtk3 là port libadwaita cho GTK3 → app GTK3 (Thunar/foliate/
#     pavucontrol) trông GIỐNG app GTK4/libadwaita, hội tụ thay vì phân kỳ.
#   • Xám-dark Adwaita đứng cạnh Mocha `#1e1e2e` ít lộ hơn Mocha tím-xanh
#     tranh tông (`#89b4fa` vs `#7aa2f7` cũ).
{
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
