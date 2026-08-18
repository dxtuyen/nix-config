{ pkgs, ... }:

# Cấu hình foot terminal (theme Tokyo Night)
# Thay thế Ghostty — nhẹ hơn, mượt hơn, tối giản

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        # Padding cân đối: 12px ngang, 8px dọc
        pad = "12x8";
        font = "JetBrainsMono Nerd Font:size=10";
      };

      # Chỉ dùng colors-dark — sway set FOOT_COLOR_SCHEME=dark nên foot dùng đúng section này
      colors-dark = {
        # Độ trong suốt 90% — nền gần đục, chữ rõ hơn
        alpha = 0.90;

        # Tokyo Night
        background = "1a1b26";
        foreground = "c0caf5";

        # Selection
        selection-background = "364a82";
        selection-foreground = "c0caf5";

        # Không set màu cursor — foot tự dùng màu foreground sáng

        # Tokyo Night palette (ANSI 16)
        regular0 = "15161e";
        regular1 = "f7768e";
        regular2 = "9ece6a";
        regular3 = "e0af68";
        regular4 = "7aa2f7";
        regular5 = "bb9af7";
        regular6 = "73daca";
        regular7 = "a9b1d6";
        bright0 = "414868";
        bright1 = "f7768e";
        bright2 = "9ece6a";
        bright3 = "e0af68";
        bright4 = "7aa2f7";
        bright5 = "bb9af7";
        bright6 = "73daca";
        bright7 = "acb0d0";
      };

      cursor = {
        # Beam (thanh dọc) — hiện đại, gọn gàng
        style = "beam";
        blink = "yes";
      };

      scrollback = {
        lines = 10000;
      };

      url = {
        launch = "xdg-open \${url}";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
