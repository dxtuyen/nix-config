# Yazi — file manager chạy trong terminal, mở bằng $mod+y (thư mục hiện tại)
# hoặc $mod+Shift+y (mở thẳng thư mục ảnh nền).
# Dùng chủ yếu để quản lý ~/Pictures/wallpapers (ảnh nền nằm NGOÀI repo):
# copy ảnh vào là xài ngay, không rebuild. Thunar vẫn giữ cho việc đồ hoạ.
#
# Cấu hình TỐI GIẢN: chỉ khai 2 mục dưới đây, phần còn lại Yazi tự lấy mặc
# định. Cố ý KHÔNG dùng `yazi.override { settings = … }` — option đó thay
# cả thư mục config nên sẽ mất sạch phím tắt mặc định của Yazi.
{ pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];

  # Yazi tự merge 2 file này với config mặc định của nó.
  # yazi.toml: hành vi (opener, tỉ lệ cột, luật mở app theo loại file).
  # theme.toml: màu — chỉ ghi đè chỗ có nền màu, xem chú thích trong file.
  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi/yazi.toml;
    "yazi/theme.toml".source = ./yazi/theme.toml;
  };
}
