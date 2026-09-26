# Ứng dụng mặc định cho từng loại file — dùng khi double-click trong Thunar,
# hoặc khi `xdg-open` / yazi gọi tới (yazi mặc định `open`/`play` = xdg-open).
#
# ⚠️ `enable = true` là BẮT BUỘC: option này mặc định `false`, nên chỉ khai
# `defaultApplications` mà quên bật thì toàn bộ khai báo bị bỏ qua im lặng
# (đã xảy ra: `text/plain = nvim.desktop` khai ở thunar.nix là dòng chết).
# Khi bật, Home-Manager tạo ~/.config/mimeapps.list (symlink) và đẩy file cũ
# (nếu có) thành `mimeapps.list.backup`.
{ pkgs, ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Tài liệu
      "application/pdf" = "sioyek.desktop";

      # Sách điện tử → foliate (dùng WebKitGTK, typography tốt nhất).
      # Thư viện: ~/Books/Textbooks (PDF) + ~/Books/Reading (epub/azw3).
      "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
      # ⚠️ `application/x-mobi8-ebook` (dòng cũ) KHÔNG phải mime thật → dòng
      # mapping mobi đó gần như chết. Hai mime đúng của foliate:
      "application/x-mobipocket-ebook" = "com.github.johnfactotum.Foliate.desktop";
      "application/vnd.amazon.mobi8-ebook" = "com.github.johnfactotum.Foliate.desktop";
      # FB2 (FictionBook) — foliate đọc trực tiếp
      "application/x-fictionbook+xml" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-zip-compressed-fb2" = "com.github.johnfactotum.Foliate.desktop";
      # Comic/manga
      "application/vnd.comicbook+zip" = "com.github.johnfactotum.Foliate.desktop";
      # Đọc sách trực tiếp từ feed OPDS
      "x-scheme-handler/opds" = "com.github.johnfactotum.Foliate.desktop";
      # ⚠️ LRF (Sony Reader): foliate KHÔNG hỗ trợ, calibre đã gỡ → KHÔNG còn app
      # nào mở được. Cố ý KHÔNG khai mapping (khai trỏ tới app không tồn tại thì
      # double-click sẽ báo lỗi khó hiểu hơn là không có ứng dụng).
      # Thư viện hiện tại không có file .lrf nào — xem ~/Books.

      # Văn phòng
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";

      # Web: ưu tiên Chrome cho mọi link + file html/xhtml
      "text/html" = "google-chrome.desktop";
      "application/xhtml+xml" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";

      # File text: mở thẳng bằng nvim trong terminal (entry `nvim.desktop`)
      "text/plain" = "nvim.desktop";

      # Ảnh → imv.
      # ⚠️ Liệt kê TAY thay vì đẩy `imv` vào `defaultApplicationPackages` bên
      # dưới: imv có 2 entry cùng khai MimeType — `imv-dir.desktop` (mở THƯ MỤC
      # chứa ảnh) và `imv.desktop` (mở đúng ảnh đó). Cơ chế merge của
      # `defaultApplicationPackages` luôn APPEND nên imv-dir sẽ đứng đầu →
      # double-click 1 ảnh lại ra cả thư mục. Ở đây ép đúng `imv.desktop`.
      "image/x-farbfeld" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/tiff-fx" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/x-png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/jpg" = "imv.desktop";
      "image/pjpeg" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/x-bmp" = "imv.desktop";
      "image/heif" = "imv.desktop";
      "image/avif" = "imv.desktop";
      "image/jxl" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/qoi" = "imv.desktop";
    };

    # Video + audio: mpv tự khai ~130 mime trong .desktop nên để cơ chế quét
    # giúp (khỏi liệt kê tay, tự đúng khi mpv đổi danh sách mime).
    # mpv không có entry "mở thư mục" nên không dính vấn đề như imv.
    defaultApplicationPackages = with pkgs; [
      mpv
    ];
  };

  # Entry Neovim mở trong Foot (không qua exo helper như Thunar).
  # Khai ở đây vì `mimeapps.nix` là nơi dùng nó (dòng `text/plain` ở trên).
  #
  # ⚠️ KHÔNG dùng `mimeType`: module `xdg.desktopEntries` dịch nó qua
  # `extraConfig` — option đã bị XOÁ ở Home-Manager 26.05 → entry không
  # được sinh file (đã xảy ra: nvim.desktop + sioyek.desktop biến mất khỏi
  # ~/.local/share/applications, còn mimeapps.list vẫn trỏ tới).
  # `settings` là option thay thế, sinh đúng dòng MimeType=.
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    comment = "Open in neovim inside foot";
    icon = "nvim";
    exec = "foot --title=nvim nvim %F";
    terminal = false;
    type = "Application";
    # Chỉ 1 "main category" (Utility); TextEditor/Development là additional
    # category — desktop-file-utils cảnh báo nếu có >1 main.
    categories = [
      "Utility"
      "TextEditor"
      "Development"
    ];
    # Một dòng, phân tách bằng dấu chấm phẩy, KHÔNG xuống dòng (xuống dòng
    # làm sinh dòng hỏng trong .desktop).
    settings.MimeType = "text/plain; text/x-makefile; text/x-c++hdr; text/x-c++src; text/x-chdr; text/x-csrc; text/x-java; text/x-moc; text/x-pascal; text/x-tcl; text/x-tex; application/x-shellscript; text/x-c; text/x-c++;";
  };
}
