# Yazi — file manager chạy trong terminal, mở bằng $mod+y.
# Dùng chủ yếu để quản lý ~/Pictures/wallpapers (ảnh nền nằm NGOÀI repo):
# copy ảnh vào là xài ngay, không rebuild. Thunar vẫn giữ cho việc đồ hoạ.
#
# Cấu hình TỐI GIẢN: chỉ khai 2 mục dưới đây, phần còn lại Yazi tự lấy mặc
# định. Cố ý KHÔNG dùng `yazi.override { settings = … }` — option đó thay
# cả thư mục config nên sẽ mất sạch phím tắt mặc định của Yazi.
{ pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];

  # Yazi tự merge file này với config mặc định của nó.
  xdg.configFile."yazi/yazi.toml".source = ./yazi/yazi.toml;
}
