# Yazi — file manager chạy trong terminal. `$mod+y` mở popup nhỏ để chọn nhanh;
# gõ `yazi` trong terminal thì cửa sổ thường (xem trước ảnh/PDF bằng sixel).
# Thunar giữ cho việc đồ hoạ, ảnh nền nằm NGOÀI repo (~/$PICTURES).
#
# Cấu hình tối giản: Yazi tự merge các file này với config mặc định. Cố ý
# KHÔNG dùng `yazi.override` — option đó thay cả thư mục config, mất phím tắt.
# Đổi sang bản yazi khác = sửa `home/yazi/keymap.toml`.
{ pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];

  # yazi.toml: hành vi · keymap.toml: phím tắt (chỉ ghi đè) · theme.toml: màu.
  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi/yazi.toml;
    "yazi/keymap.toml".source = ./yazi/keymap.toml;
    "yazi/theme.toml".source = ./yazi/theme.toml;
  };

  # Plugin smart-enter: <Enter> mở app theo mime. CẦN vì preset yazi khai
  # `{ mime = "folder/*", use = ["edit", …] }` mà ta ghi đè opener `edit` thành
  # nvim → Enter vào thư mục lại ra nvim. KHÔNG dùng `programs.yazi.plugins` của
  # Home-Manager (kéo theo finalPackage override + shell integration); lấy từ
  # `pkgs` để khớp phiên bản yazi.
  xdg.configFile."yazi/plugins/smart-enter.yazi".source = pkgs.yaziPlugins.smart-enter;
}
