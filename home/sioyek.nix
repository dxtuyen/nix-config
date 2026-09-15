{ userName, ... }:

{
  # Sioyek mặc định là single-instance: launch lần 2 chỉ mở file vào instance
  # đang chạy (process mới gửi IPC rồi thoát ngay). Bật nhiều "phiên" = mỗi
  # file mới mở một CỬA SỔ RIÊNG (vẫn 1 process, nhẹ RAM; bookmarks/highlights/
  # portal vẫn dùng chung database nên ghi chú ở sách này xem được từ sách khác).
  # Cửa sổ mới luôn hiện ở workspace đang focus nhờ rule for_window trong
  # home/sway.nix.
  xdg.configFile."sioyek/prefs_user.config".text = ''
    should_launch_new_window 1
  '';

  # Đè desktop entry của package (cùng ID sioyek.desktop → bản ở
  # ~/.local/share/applications thắng) để mọi đường mở file (Thunar,
  # xdg-open, trình duyệt, rofi) đi qua sioyek-open thay vì gọi binary
  # trực tiếp — tránh hiện tượng "mở lại file đã mở thì không thấy cửa
  # sổ lên" (app không được tự focus trên Wayland). mimeapps.list hiện
  # trỏ application/pdf=sioyek.desktop nên tự dùng entry mới, không cần
  # sửa gì thêm.
  xdg.desktopEntries.sioyek = {
    type = "Application";
    name = "Sioyek";
    comment = "PDF viewer for reading research papers and technical books";
    # QUAN TRỌNG: gọi bằng ĐƯỜNG DẪN TUYỆT ĐỐI. PATH của session sway
    # không chứa ~/.local/bin (chỉ bash thêm vào), nên nếu ghi bare
    # `sioyek-open` thì Thunar/gio sẽ "command not found" → bấm PDF không
    # mở gì cả.
    exec = "/home/${userName}/.local/bin/sioyek-open %f";
    icon = "sioyek-icon-linux";
    categories = [
      "Development"
      "Viewer"
    ];
    mimeType = [ "application/pdf" ];
    terminal = false;
    startupNotify = true;
    # HM mới đã gỡ extraConfig; schema mới là `settings` (key-value raw
    # thêm vào section [Desktop Entry])
    settings.StartupWMClass = "sioyek";
  };
}
