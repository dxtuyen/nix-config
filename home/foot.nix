# Foot — terminal mặc định (thay Alacritty), theme Tokyo Night, native Wayland.
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

      # Tokyo Night. CỐ Ý chỉ khai 16 màu ANSI + nền/foreground/cursor — bảng 256
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
        background = "1a1b26";
        foreground = "c0caf5";
        # chữ `1a1b26` trên nền con trỏ `c0caf5`
        cursor = "1a1b26 c0caf5";
        "selection-foreground" = "c0caf5";
        "selection-background" = "364a82";

        # ANSI 0-7
        regular0 = "15161e";
        regular1 = "f7768e";
        regular2 = "9ece6a";
        regular3 = "e0af68";
        regular4 = "7aa2f7";
        regular5 = "bb9af7";
        regular6 = "73daca";
        regular7 = "a9b1d6";

        # ANSI 8-15
        bright0 = "414868";
        bright1 = "f7768e";
        bright2 = "9ece6a";
        bright3 = "e0af68";
        bright4 = "7aa2f7";
        bright5 = "bb9af7";
        bright6 = "73daca";
        bright7 = "acb0d0";

        # Đều là cặp "chữ nền" — xem chú thích cú pháp ở trên.
        "jump-labels" = "15161e e0af68";
        "scrollback-indicator" = "15161e 7aa2f7";
        "search-box-match" = "15161e e0af68";
        "search-box-no-match" = "15161e f7768e";
      };
    };
  };
}
