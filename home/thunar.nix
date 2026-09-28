# Thunar cho việc đồ hoạ. Thùng rác GIO chạy sẵn nhờ `services.gvfs.enable` ở
# modules/nixos/desktop.nix (xoá mềm bằng `d` của yazi), dọn lúc 03:00 hằng ngày
# do user timer `trash-clean` đảm nhiệm — thùng rác ngoài repo nên không khai
# ở đây (chi tiết: docs/02).
#
# Module này chỉ còn việc đúng nghĩa: đặt terminal cho libexo (Thunar đọc
# `TerminalEmulator` cho action "Open Terminal Here" — action mặc định của
# thunar-uca nên không cần khai uca.xml). Ứng dụng mặc định theo loại file và
# entry `nvim.desktop` cho text nằm ở `home/mimeapps.nix`.
{
  xdg.configFile."xfce4/helpers.rc".text = "TerminalEmulator=foot\n";
}
