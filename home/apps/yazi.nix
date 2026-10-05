# Yazi runs in the terminal; Mod+y opens its popup.
# Its config files are merged with Yazi's defaults.
{ pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];

  # Behavior, keybindings, and theme.
  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi/yazi.toml;
    "yazi/keymap.toml".source = ./yazi/keymap.toml;
    "yazi/theme.toml".source = ./yazi/theme.toml;
  };

  # Use smart-enter to enter directories and open files with their default app.
  xdg.configFile."yazi/plugins/smart-enter.yazi".source = pkgs.yaziPlugins.smart-enter;
}
