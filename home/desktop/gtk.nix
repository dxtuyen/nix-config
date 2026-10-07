# Cursor + GTK theme (adw-gtk3-dark) + icons (Papirus-Dark).
# Most elements paint themselves with Catppuccin Mocha; GTK alone uses neutral
# adw-gtk3-dark: catppuccin/gtk is archived, tokyonight-gtk-theme was removed
# from nixpkgs, and it makes GTK3 apps look like GTK4/libadwaita apps.
{ pkgs, ... }:

{
  home.pointerCursor = {
    # Required since HM 25.11+ (missing it triggers a deprecation warning).
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
