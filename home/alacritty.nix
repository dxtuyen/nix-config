{ pkgs, ... }:

# Cấu hình Alacritty terminal (theme Tokyo Night)
# Thay thế Foot — GPU-accelerated, TOML config chuẩn v0.13+
# Rice theo phong cách cộng đồng: padding thoáng, nền trong nhẹ, cursor beam

{
  programs.alacritty = {
    enable = true;

    settings = {
      # Tự nạp lại khi sửa ~/.config/alacritty/alacritty.toml
      general.live_config_reload = true;

      # Cửa sổ: padding cân đối + trong suốt 90% (giống foot cũ),
      # dynamic_padding dàn đều khoảng trống khi cửa sổ to hơn lưới ký tự
      window = {
        padding = {
          x = 12;
          y = 8;
        };
        dynamic_padding = true;
        opacity = 0.9;
        decorations = "None";
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 10.0;
      };

      # Beam (thanh dọc) nhấp nháy — hiện đại, gọn gàng
      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
        blink_interval = 550;
      };

      scrolling.history = 10000;

      mouse.hide_when_typing = true;

      selection.save_to_clipboard = true;

      colors = {
        primary = {
          background = "#1a1b26";
          foreground = "#c0caf5";
        };

        cursor = {
          text = "#1a1b26";
          cursor = "#c0caf5";
        };

        vi_mode_cursor = {
          text = "#1a1b26";
          cursor = "#73daca";
        };

        selection = {
          text = "#c0caf5";
          background = "#364a82";
        };

        search.matches = {
          foreground = "#1a1b26";
          background = "#e0af68";
        };
        search.focused_match = {
          foreground = "#1a1b26";
          background = "#9ece6a";
        };

        # Tokyo Night palette (ANSI 16)
        normal = {
          black = "#15161e";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#73daca";
          white = "#a9b1d6";
        };

        bright = {
          black = "#414868";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#73daca";
          white = "#acb0d0";
        };
      };
    };
  };
}
