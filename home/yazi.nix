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
#
# ⭐ VÌ SAO `yazi` LẤY TỪ `unstablePkgs` (nixpkgs-unstable) CÒN MỌI GÓI KHÁC
# LẤY TỪ `pkgs` (nixos-26.05):
# nixpkgs 26.05 đóng gói yazi 26.5.6 — bản này CHƯA có tính năng "Trash bin".
# Hai lỗi đã kiểm chứng trên máy, đều do `remove` không biết mình đang ở
# trong thùng rác hay không:
#   • `d` trong thùng rác không xoá, mà GHI LẠI vào thùng rác — file thành
#     `X.2`, `X.2.2`, ... kèm `.trashinfo` mới (crate `trash-rs` tự sinh tên).
#   • `D` xoá file nhưng để lại `.trashinfo` mồ côi (đã dư 52 file rác).
# unstable có yazi 26.9.1 (có sẵn trong binary cache, không phải build):
#   • `g t` mở thùng rác thật (scheme `trash://`), có cột đường dẫn gốc
#   • `D` xoá sạch cả file lẫn `.trashinfo`
# ⚠️ Chỉ gói yazi lấy từ unstable. Đổi sang bản khác = sửa `home/yazi/keymap.toml`.
{ pkgs, unstablePkgs, ... }:

{
  home.packages = [ unstablePkgs.yazi ];

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
  # ⚠️ `smart-enter` KHÔNG cần `setup()` — chỉ cần khi muốn `open_multi = true`
  # (mở cả nhóm file đang tick thay vì đúng 1 file đang trỏ).
  #
  # ⚠️ Lấy `yaziPlugins` từ unstable, KHỚP phiên bản yazi 26.9.1.
  xdg.configFile."yazi/plugins/smart-enter.yazi".source = unstablePkgs.yaziPlugins.smart-enter;
}
