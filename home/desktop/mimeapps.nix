# Default applications for Thunar, xdg-open, and Yazi.
{ pkgs, lib, ... }:

let
  # MIME types handled by Neovim.
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

  # Do not add spaces after semicolons; MIME list parsing does not trim them.
  sepMime = lib.concatStringsSep ";";
in

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Documents
      "application/pdf" = "sioyek.desktop";

      # E-books
      "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-mobipocket-ebook" = "com.github.johnfactotum.Foliate.desktop";
      "application/vnd.amazon.mobi8-ebook" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-fictionbook+xml" = "com.github.johnfactotum.Foliate.desktop";
      "application/x-zip-compressed-fb2" = "com.github.johnfactotum.Foliate.desktop";
      # Comics and manga
      "application/vnd.comicbook+zip" = "com.github.johnfactotum.Foliate.desktop";
      # OPDS feeds
      "x-scheme-handler/opds" = "com.github.johnfactotum.Foliate.desktop";
      # Foliate does not support .lrf; leave it unassigned.

      # Office documents
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";

      # Open web links and HTML files in Chrome.
      "text/html" = "google-chrome.desktop";
      "application/xhtml+xml" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";

      # Open text files in Neovim inside Foot.
      "text/plain" = "nvim.desktop";

      # List image types explicitly so imv opens files instead of its directory view.
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

    # Let mpv provide its video and audio MIME types.
    defaultApplicationPackages = with pkgs; [
      mpv
    ];
  };

  # Desktop entry for Neovim inside Foot.
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    comment = "Open in neovim inside foot";
    icon = "nvim";
    exec = "foot --title=nvim nvim %F";
    terminal = false;
    type = "Application";
    # Use one main category and one additional category to avoid duplicate entries.
    categories = [
      "Utility"
      "TextEditor"
    ];
    settings.MimeType = sepMime nvimMimeTypes + ";";
  };
}
