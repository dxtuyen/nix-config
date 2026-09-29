# Cursor + GTK theme (adw-gtk3-dark) + icon (Papirus-Dark).
# Phần tử vẽ tự dùng Catppuccin Mocha; riêng GTK dùng adw-gtk3-dark trung tính:
# catppuccin/gtk đã archive, tokyonight-gtk-theme đã bị xoá khỏi nixpkgs, và nó
# cho app GTK3 trông giống app GTK4/libadwaita.
{ pkgs, ... }:

{
  home.pointerCursor = {
    # Bắt buộc từ HM 25.11+ (thiếu sẽ warning deprecated).
    enable = true;
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
