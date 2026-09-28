# Ứng dụng mặc định theo loại file — dùng khi double-click trong Thunar hoặc
# khi `xdg-open` / yazi gọi tới.
#
# `enable = true` là BẮT BUỘC (mặc định `false`) — quên bật thì toàn bộ
# `defaultApplications` bị bỏ qua im lặng.
{ pkgs, lib, ... }:

let
  # MIME mà nvim nhận. Mỗi MIME một dòng để không lỡ tay thêm space.
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

  # List phải là 1 dòng, phân tách bằng `;` TRẦN: spec không trim, nên "a; b"
  # sinh MIME " b" (sai) và update-desktop-database bỏ chỉ mục.
  sepMime = lib.concatStringsSep ";";
in

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Tài liệu
      "application/pdf" = "sioyek.desktop";

      # Sách điện tử → foliate (WebKitGTK, typography tốt nhất).
      # Thư viện: ~/Books/Textbooks (PDF) + ~/Books/Reading (epub/azw3).
      "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-mobipocket-ebook" = "com.github.johnfactotum.Foliate.desktop";
      "application/vnd.amazon.mobi8-ebook" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-fictionbook+xml" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-zip-compressed-fb2" = "com.github.johnfactotum.Foliate.desktop";
      # Comic/manga
      "application/vnd.comicbook+zip" = "com.github.johnfactotum.Foliate.desktop";
      # Đọc sách trực tiếp từ feed OPDS
      "x-scheme-handler/opds" = "com.github.johnfactotum.Foliate.desktop";
      # KHÔNG khai .lrf: foliate không hỗ trợ, calibre đã gỡ. Trỏ tới app không
      # tồn tại thì double-click báo lỗi khó hiểu hơn là để trống.

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

      # Ảnh → imv. Liệt kê TAY: imv có 2 entry cùng khai MimeType (`imv-dir`
      # mở THƯ MỤC ảnh), mà merge `defaultApplicationPackages` luôn APPEND
      # → imv-dir đứng đầu, double-click 1 ảnh ra cả thư mục.
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

    # Video + audio: mpv tự khai ~130 mime trong .desktop nên để quét giúp
    # (đúng khi mpv đổi danh sách). Không dính vấn đề entry trùng như imv.
    defaultApplicationPackages = with pkgs; [
      mpv
    ];
  };

  # Entry Neovim mở trong Foot (không qua exo helper như Thunar).
  # KHÔNG dùng `mimeType` (option đã bị xoá ở HM 26.05) — dùng `settings`.
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    comment = "Open in neovim inside foot";
    icon = "nvim";
    exec = "foot --title=nvim nvim %F";
    terminal = false;
    type = "Application";
    # Chỉ 1 main category (Utility); `TextEditor` là additional nên đi kèm hợp lệ,
    # `Development` thì không (cũng là main → app hiện 2 lần trong menu).
    categories = [
      "Utility"
      "TextEditor"
    ];
    settings.MimeType = sepMime nvimMimeTypes + ";";
  };
}
