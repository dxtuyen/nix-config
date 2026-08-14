{ pkgs, ... }:

{
  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      package = pkgs.noto-fonts;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
