# Thunar GIỮ LẠI (giao diện đồ hoạ) + dùng Foot làm terminal mặc định.
#
# Thùng rác GIO hoạt động sẵn (nhờ `services.gvfs.enable` ở
# modules/nixos/desktop.nix) — "Move to Trash" của Thunar và phím `d` của yazi
# đều xoá mềm. KHÔNG khai option nào ở đây.
# Tự dọn mục > 30 ngày lúc 03:00 do systemd USER timer `trash-clean` đảm nhiệm
# (cùng file desktop.nix) — thùng rác KHÔNG nằm trong repo nên không cần khai
# ở module này. Chi tiết + cách khôi phục: docs/02.
#
# KHÔNG có thunar-archive-plugin (xem modules/nixos/desktop.nix): nén/giải nén
# bằng lệnh `7z` cho nhẹ, không kéo cả GNOME stack.
#
# ⚠️ Module này CHỈ còn việc đúng nghĩa: đặt terminal cho libexo (Thunar đọc
# `TerminalEmulator` ở đây khi chạy action "Open Terminal Here").
# - Ứng dụng mặc định theo loại file → `home/mimeapps.nix`
#   (nhớ rằng `xdg.mimeApps` phải bật `enable`).
# - Entry `nvim.desktop` cho text → cũng ở `home/mimeapps.nix`, nơi nó được
#   dùng. Trước đây đặt ở đây là sai chỗ.
{
  # libexo dùng Foot làm terminal khi Thunar gọi exo-open.
  # Action "Open Terminal Here" là action mặc định của thunar-uca, nên không
  # cần khai uca.xml (nếu muốn thêm action riêng thì khai ở đây, xem docs/02).
  xdg.configFile."xfce4/helpers.rc".text = "TerminalEmulator=foot\n";
}
