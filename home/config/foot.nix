# Foot — default terminal, Catppuccin Mocha, native Wayland. Chosen because it supports
# **sixel** -> yazi shows real images in the preview pane; the nixpkgs build compiles
# with `--sixel` + terminfo (`TERM=foot`).
#
# 📌 `alpha`: foot makes the background translucent itself (vanilla Sway has no
# compositor-level blur, so this is the only such effect). 0.75 = translucent enough
# to see the wallpaper behind while text stays crisp; 0.9+ makes it nearly opaque.
#
# ⚠️ COLOR SYNTAX: single = `RRGGBB` (6 hex digits, NO `#`); pairs (cursor, jump-labels,
# scrollback-indicator, search-box-*) = TWO hex colors separated by WHITESPACE, order is
# `text-color background-color`. On a syntax error foot prints `err: config.c:...`;
# verify with `foot -C` without opening a window.
{ ... }:

{
  programs.foot = {
    enable = true;

    # Generates $XDG_CONFIG_HOME/foot/foot.ini.
    settings = {
      main = {
        # Matches the old Alacritty font + size.
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "10x8";
      };

      scrollback.lines = 10000;

      mouse.hide-when-typing = "yes";

      # Open a new window with `nt`; do not use the default spawn-terminal key.
      "key-bindings".spawn-terminal = "none";

      cursor = {
        style = "beam";
        blink = "yes";
        blink-rate = 550;
        beam-thickness = 1.5;
      };

      # Declare only the 16 ANSI colors + background/foreground/cursor; the 256-color
      # table (term-colors 16-255) keeps foot's defaults. Add more here if wanted.
      colors-dark = {
        # 0.75 (not 0.9): translucent enough to see the wallpaper, text still crisp.
        alpha = 0.85;
        background = "1e1e2e";
        foreground = "cdd6f4";
        cursor = "1e1e2e f5e0dc"; # text `1e1e2e` on cursor background `f5e0dc`
        "selection-foreground" = "cdd6f4";
        "selection-background" = "585b70";

        # ANSI 0-7 (Catppuccin Mocha: crust/surface + accent colors)
        regular0 = "45475a";
        regular1 = "f38ba8";
        regular2 = "a6e3a1";
        regular3 = "f9e2af";
        regular4 = "89b4fa";
        regular5 = "cba6f7";
        regular6 = "94e2d5";
        regular7 = "bac2de";

        # ANSI 8-15
        bright0 = "585b70";
        bright1 = "f38ba8";
        bright2 = "a6e3a1";
        bright3 = "f9e2af";
        bright4 = "89b4fa";
        bright5 = "cba6f7";
        bright6 = "94e2d5";
        bright7 = "a6adc8";

        # All are "text background" pairs.
        "jump-labels" = "1e1e2e fab387";
        "scrollback-indicator" = "1e1e2e 89b4fa";
        "search-box-match" = "1e1e2e fab387";
        "search-box-no-match" = "1e1e2e f38ba8";
      };
    };
  };
}
