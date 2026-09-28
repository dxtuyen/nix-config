# Foot — terminal mặc định (thay Alacritty), theme Catppuccin Mocha, native Wayland.
# Chọn foot vì hỗ trợ **sixel** → yazi hiện được ảnh thật trong khung preview
# (Alacritty không có kitty-graphics lẫn sixel). Bản foot trong nixpkgs build kèm
# `--sixel` + terminfo (`TERM=foot`) — đúng thứ yazi cần để nhận diện Sixel driver.
#
# Sway không có blur ⇒ "acrylic" không tồn tại. Foot có khoá `blur = yes` nhưng
# cần protocol `ext-background-effect-manager-v1` (chỉ KDE Plasma 6.1+) nên bị bỏ
# qua. Ở đây chỉ dùng trong suốt phẳng (alpha); muốn giống kính mờ thì dùng ảnh
# nền ĐÃ BLUR SẴN.
#
# ⚠️ Cú pháp màu: đơn = `RRGGBB` (6 hex, không `#`); cặp (cursor, jump-labels,
# scrollback-indicator, search-box-*) = HAI màu hex CÁCH NHAU KHOẢNG TRẮNG,
# thứ tự `màu-chữ màu-nền` — không dùng `/` và không dùng tên `regular0`.
# Sai cú pháp thì foot in `err: config.c:...` ngay khi mở cửa sổ mới;
# kiểm tra không cần mở cửa sổ bằng `foot -C`.
{ ... }:

{
  programs.foot = {
    enable = true;

    # foot đọc: $XDG_CONFIG_HOME/foot/foot.ini (sinh ra từ `settings`).
    settings = {
      main = {
        # Khớp font + cỡ chữ cũ của Alacritty (default của Alacritty là 11).
        font = "JetBrainsMono Nerd Font:size=11";
        # Cùng padding với Alacritty cũ (x=10, y=8).
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

      # Catppuccin Mocha. CỐ Ý chỉ khai 16 màu ANSI + nền/foreground/cursor — bảng 256
      # màu (term-colors 16-255) giữ mặc định của foot, y hệt trước đây khi
      # config Alacritty cũng chỉ khai 16 màu. Muốn khai thêm thì thêm ở đây.
      #
      # ⚠️ CÚ PHÁP MÀU TRONG FOOT (sai là foot in "err: config.c:..." ngay khi
      # mở cửa sổ mới):
      #  - Màu đơn: `RRGGBB` (6 chữ số hex, KHÔNG có dấu `#`). Ở các khoá bảng
      #    màu (regular0..7, bright0..7) mới được dùng tên như `regular3`.
      #  - Màu CẶP (cursor, jump-labels, scrollback-indicator, search-box-*):
      #    HAI màu RGB hex CÁCH NHAU BỞI KHOẢNG TRẮNG, theo thứ tự
      #    `màu-chữ màu-nền`. KHÔNG dùng `/` làm dấu phân cách, và KHÔNG dùng
      #    tên `regular0` (foot chỉ nhận RGB hex cho các khoá này).
      colors-dark = {
        # Trong suốt phẳng (không có blur — xem LƯU Ý trên đầu file).
        alpha = 0.9;
        background = "1e1e2e";
        foreground = "cdd6f4";
        # chữ `1e1e2e` trên nền con trỏ `f5e0dc`
        cursor = "1e1e2e f5e0dc";
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

        # Đều là cặp "chữ nền" — xem chú thích cú pháp ở trên.
        "jump-labels" = "1e1e2e fab387";
        "scrollback-indicator" = "1e1e2e 89b4fa";
        "search-box-match" = "1e1e2e fab387";
        "search-box-no-match" = "1e1e2e f38ba8";
      };
    };
  };
}
