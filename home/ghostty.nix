{ pkgs, ... }:

# Cấu hình Ghostty terminal (theme Tokyo Night)
# Màu khai báo trực tiếp — không cần file theme bên ngoài

{
  xdg.configFile = {
    "ghostty/config".text = ''
      # Tokyo Night colors
      background = 1a1b26
      foreground = c0caf5
      cursor-color = 7aa2f7
      cursor-text = 1a1b26
      selection-background = 364a82
      selection-foreground = c0caf5

      # Font
      font-family = Hack Nerd Font
      font-size = 10

      # Window
      background-opacity = 0.95
      window-padding-x = 10
      window-padding-y = 10
      window-decoration = false

      # Cursor
      cursor-style = block
      cursor-style-blink = true

      # Shell
      shell-integration = detect

      # Tokyo Night palette (ANSI 16 colors)
      palette = 0=15161e
      palette = 1=f7768e
      palette = 2=9ece6a
      palette = 3=e0af68
      palette = 4=7aa2f7
      palette = 5=bb9af7
      palette = 6=73daca
      palette = 7=a9b1d6
      palette = 8=414868
      palette = 9=f7768e
      palette = 10=9ece6a
      palette = 11=e0af68
      palette = 12=7aa2f7
      palette = 13=bb9af7
      palette = 14=73daca
      palette = 15=acb0d0
    '';
  };
}
