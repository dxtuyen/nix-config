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
  # ⚠️ `smart-enter` KHÔNG cần `setup()` — chỉ cần khi muốn `open_multi = true`
  # (mở cả nhóm file đang tick thay vì đúng 1 file đang trỏ).
  #
  # ⚠️ `init.lua` dưới đây là BẮT BUỘC cho `recycle-bin` (xem phần ngay sau),
  # đừng xoá. Không liên quan gì tới smart-enter.
  xdg.configFile."yazi/plugins/smart-enter.yazi".source = pkgs.yaziPlugins.smart-enter;

  # ── Plugin: recycle-bin (duyệt / khôi phục thùng rác) ──────────────────────
  # Gắn phím `g t` — đúng preset chính thức của yazi (đã grep preset `main`:
  # `{ on = [ "g","t" ], run = "plugin trash", desc = "Go to trash bin" }`, cùng
  # nhóm với `g h` / `g c` / `g d` / `g f` → `g` = "go to", `t` = trash).
  #
  # Bản 26.5.6 CHƯA có sẵn binding đó (đã kiểm trực tiếp binary: không có chuỗi
  # "Go to trash bin"; scheme `trash://` mới xuất hiện ở nightly). Nhưng `d`
  # xoá mềm thì vẫn chạy sẵn — 26.5.6 chỉ thiếu phần XEM / KHÔI PHỤC, nên
  # plugin này bù lại đúng chỗ đó.
  #
  # Đã đọc source để chắc chắn chạy được với 26.5.6:
  #   - không dùng `fs.trash` (API mới, 26.5.6 chưa có) ✔
  #   - chỉ dùng `fs.cha` + `fs.remove` (đã có sẵn) ✔
  #   - gọi shell: trash-list / trash-restore / trash-rm / trash-empty → cần
  #     gói `trash-cli` (đã khai ở home/packages.nix) ✔
  xdg.configFile."yazi/plugins/recycle-bin.yazi".source = pkgs.yaziPlugins.recycle-bin;

  # ⚠️ `setup()` BẮT BUỘC: entry đọc config từ state, không có setup thì
  # `config` = nil → các lệnh dùng `config.trash_dir` sẽ lỗi. Gọi không tham số
  # để dùng default (trash_dir tự dò qua `trash-list --trash-dirs`).
  xdg.configFile."yazi/init.lua".text = ''
    require("recycle-bin"):setup()
  '';
}
