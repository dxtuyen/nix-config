{ pkgs, ... }:

# Gói user: nixos-unstable (pinned trong flake.lock). TickTick dùng bản web/PWA (xem docs/02).
{

  home.packages = with pkgs; [
    rofi
    swayr # switch windows by focus history (Alt+Tab-style MRU)
    wlsunset
    grim
    slurp
    wl-clipboard
    swaylock
    swayidle
    awww # daemon wallpaper (fork của swww) — transition hoạt ảnh, đổi nền runtime
    libnotify
    pavucontrol
    brightnessctl
    translate-shell
    goldendict-ng
    wifitui # TUI quản lý Wi-Fi hiện đại (hỗ trợ bật/tắt radio, fuzzy search, QR code)

    bluetui
    google-chrome
    # Sách: foliate đọc epub/mobi/azw3/fb2/cbz/opds (typography tốt hơn calibre
    # đã gỡ; thư viện ở ~/Books/{Textbooks,Reading}).
    foliate
    imv # xem ảnh (nhẹ, có zoom/timeline)
    mpv # xem video/nhạc
    ripgrep # tìm nội dung nhanh (thay grep)
    fd # tìm file nhanh (thay find)
    dust # xem dung lượng dạng thanh bar (bản nixpkgs tên là du-dust)
    ncdu # TUI xem + di chuyển/xóa file theo dung lượng
    sioyek
    obsidian
    # Zotero: TẠM GỠ — bản 10.0.2 trong nixpkgs (rev c59305ba) build hỏng:
    #   AboutTranslations: ... not found in modules/ActorManagerParent.sys.mjs -- aborting
    # Bản 10.0.4 đã có trên nixpkgs master (chỉ khác version + src.hash) →
    # bật lại dòng dưới sau khi `nix flake update nixpkgs`.
    # zotero # quản lý tài liệu tham khảo — thư viện mặc định ở ~/Zotero
    jq
    fastfetch
    libreoffice
    # Dev: thư viện để per-project (venv / `nix develop`), không cài global.
    vscode
    python3
    python3Packages.virtualenv
    gcc
    gnumake
    cmake
    gdb
    jdk
    distrobox
    gh # GitHub CLI — tạo/xem PR, issue, release từ terminal
    # Máy ảo — luyện cài máy mới (docs/06).
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
