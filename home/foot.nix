# Foot — terminal mặc định, Catppuccin Mocha, native Wayland. Chọn vì hỗ trợ
# **sixel** → yazi hiện được ảnh thật trong khung preview; bản nixpkgs build kèm
# `--sixel` + terminfo (`TERM=foot`).
#
# ⚠️ CÚ PHÁP MÀU: đơn = `RRGGBB` (6 hex, KHÔNG có `#`); cặp (cursor, jump-labels,
# scrollback-indicator, search-box-*) = HAI màu hex cách nhau KHOẢNG TRẮNG, thứ
# tự `màu-chữ màu-nền`. Sai cú pháp thì foot in `err: config.c:...`; kiểm tra
# bằng `foot -C` không cần mở cửa sổ.
{ ... }:

{
  programs.foot = {
    enable = true;

    # Sinh ra $XDG_CONFIG_HOME/foot/foot.ini.
    settings = {
      main = {
        # Khớp font + cỡ chữ cũ của Alacritty.
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "10x8";
      };

      scrollback.lines = 10000;

      mouse.hide-when-typing = "yes";

      cursor = {
        style = "beam";
        blink = "yes";
        blink-rate = 550;
        beam-thickness = 1.5;
      };

      # Chỉ khai 16 màu ANSI + nền/foreground/cursor; bảng 256 màu
      # (term-colors 16-255) giữ mặc định của foot. Muốn thêm thì khai ở đây.
      colors-dark = {
        alpha = 0.9; # trong suốt phẳng (không có blur — xem chú thích trên đầu file)
        background = "1e1e2e";
        foreground = "cdd6f4";
        cursor = "1e1e2e f5e0dc"; # chữ `1e1e2e` trên nền con trỏ `f5e0dc`
        "selection-foreground" = "cdd6f4";
        "selection-background" = "585b70";

        # ANSI 0-7 (Catppuccin Mocha: crust/surface + màu chính)
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

        # Đều là cặp "chữ nền".
        "jump-labels" = "1e1e2e fab387";
        "scrollback-indicator" = "1e1e2e 89b4fa";
        "search-box-match" = "1e1e2e fab387";
        "search-box-no-match" = "1e1e2e f38ba8";
      };
    };
  };
}
