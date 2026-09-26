# Yazi — file manager chạy trong terminal.
#
# Hai cách mở, KHÁC NHAU VỀ KIỂU CỬA SỔ:
#   - `$mod+y` → script `yazi-open` → CỬA SỔ POPUP nhỏ (foot --title=yazi-popup,
#     sway làm floating). Chọn nhanh: xem 1 file, thêm/xoá ảnh.
#   - gõ `yazi` trong terminal → cửa sổ thường, KHÔNG popup, xem trước ảnh/PDF
#     bằng sixel đẹp hơn. Dùng khi cần duyệt file kỹ.
#
# Thư mục ảnh nền `~/Pictures/wallpapers` do `home.activation` tạo sẵn
# (ảnh nằm NGOÀI repo: cp/rm thoải mái, không rebuild, không commit).
# Thunar vẫn giữ cho việc đồ hoạ.
#
# Cấu hình TỐI GIẢN: chỉ khai những mục dưới đây, phần còn lại Yazi tự lấy mặc
# định. Cố ý KHÔNG dùng `yazi.override { settings = … }` — option đó thay
# cả thư mục config nên sẽ mất sạch phím tắt mặc định của Yazi.
{ pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];

  # Yazi tự merge 3 file này với config mặc định của nó.
  # yazi.toml:   hành vi (opener, tỉ lệ cột, luật mở app theo loại file).
  # keymap.toml: phím tắt (chỉ phần GHI ĐÈ, giữ nguyên preset).
  # theme.toml:  màu — chỉ ghi đè chỗ có nền màu, xem chú thích trong file.
  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi/yazi.toml;
    "yazi/keymap.toml".source = ./yazi/keymap.toml;
    "yazi/theme.toml".source = ./yazi/theme.toml;
  };

  # ── Plugin: smart-enter ────────────────────────────────────────────────────
  # Dùng cho <Enter>: thư mục thì vào, file thì mở app theo mime.
  # ⭐ Lý do CẦN: preset yazi khai `{ mime = "folder/*", use = ["edit", …] }`
  # (edit đứng đầu) + ta ghi đè opener `edit` thành nvim → Enter vào folder
  # ra nvim. smart-enter rẽ nhánh theo loại mục nên sửa đúng gốc. Chi tiết ở
  # `home/yazi/keymap.toml`.
  #
  # Home-Manager link gói này thành ~/.config/yazi/plugins/smart-enter.yazi
  # → đúng tên mà `run = "plugin smart-enter"` trong keymap.toml tìm tới.
  #
  # ⚠️ KHÔNG dùng `programs.yazi.plugins` (option có sẵn của Home-Manager):
  # bật nó sẽ kéo theo `finalPackage` override + bash/fish/zsh integration,
  # đổi hành vi ngoài ý muốn. `home/yazi.nix` cố ý làm thủ công.
  #
  # ⚠️ KHÔNG cần `init.lua`: mặc định plugin truyền `--hovered` cho `open`
  # nên chỉ mở đúng file đang trỏ chuột (khớp hành vi `enter`, tránh mở
  # nhầm cả nhóm file đang chọn). Muốn mở được cả nhóm thì mới cần
  # `require("smart-enter"):setup { open_multi = true }` trong init.lua.
  xdg.configFile."yazi/plugins/smart-enter.yazi".source = pkgs.yaziPlugins.smart-enter;
}
