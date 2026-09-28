# Ứng dụng mặc định cho từng loại file — dùng khi double-click trong Thunar,
# hoặc khi `xdg-open` / yazi gọi tới (yazi mặc định `open`/`play` = xdg-open).
#
# ⚠️ `enable = true` là BẮT BUỘC: option này mặc định `false`, nên chỉ khai
# `defaultApplications` mà quên bật thì toàn bộ khai báo bị bỏ qua im lặng
# (đã xảy ra: `text/plain = nvim.desktop` khai ở thunar.nix là dòng chết).
# Khi bật, Home-Manager tạo ~/.config/mimeapps.list (symlink) và đẩy file cũ
# (nếu có) thành `mimeapps.list.backup`.
{ pkgs, lib, ... }:

let
  # Danh sách MIME mà nvim nhận.
  #
  # ⚠️ BẮT BUỘC ghép bằng `;` KHÔNG kèm khoảng trắng (xem `sepMime` bên dưới).
  # Khai dạng danh sách Nix thay vì chuỗi "a; b; c" viết tay: mỗi MIME một
  # dòng nên không thể lỡ tay thêm space, và thêm/bớt MIME không sợ sai dấu `;`.
  nvimMimeTypes = [
    "text/plain"
    "text/x-makefile"
    "text/x-c++hdr"
    "text/x-c++src"
    "text/x-chdr"
    "text/x-csrc"
    "text/x-java"
    "text/x-moc"
    "text/x-pascal"
    "text/x-tcl"
    "text/x-tex"
    "application/x-shellscript"
    "text/x-c"
    "text/x-c++"
  ];

  # Ghép danh sách thành giá trị cho khoá `MimeType` của Desktop Entry Spec.
  #
  # Spec định nghĩa đây là LIST phân tách bằng `;` và mỗi phần tử được giữ
  # NGUYÊN VẸN — không tự trim. Nên chuỗi "text/plain; text/x-c" sinh ra hai
  # phần tử: "text/plain" và " text/x-c" (CÓ SPACE ĐẦU). Khi đó
  # `update-desktop-database` in cảnh báo:
  #     Error in file ".../nvim.desktop": " text/x-c" is an invalid MIME type
  #     (" text" is an unregistered media type)
  # và TỪ CHỐI lập chỉ mục cho 13 MIME bị dính space. Mối lo đáng ghi:
  # GIO/Thunar thì nhân nhẫn và tự cắt space nên vẫn mở đúng — lỗi chỉ lộ
  # ra lúc build, dễ bị tưởng là vô hại.
  #
  # `sepMime` dùng chung cho mọi khoá list trong file này để không bao giờ
  # quên quy tắc. Dấu `;` cuối cùng là bắt buộc theo spec (báo hết danh sách).
  sepMime = lib.concatStringsSep ";";
in

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
    # Chỉ đúng 1 "main category" (Utility). `TextEditor` là *additional*
    # category nên đi kèm hợp lệ; `Development` thì KHÔNG — theo spec nó cũng
    # là main category, nên để cả hai sẽ khiến app hiện 2 lần trong menu.
    categories = [
      "Utility"
      "TextEditor"
    ];
    # Giá trị list, phải là MỘT DÒNG (xuống dòng làm sinh dòng hỏng trong
    # .desktop) và phân tách bằng `;` trần — xem giải thích ở `sepMime`.
    settings.MimeType = sepMime nvimMimeTypes + ";";
  };
}
