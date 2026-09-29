{ pkgs, ... }:

# Gói user: nixos-unstable (pinned trong flake.lock). TickTick dùng bản web/PWA (xem docs/02).
{

  home.packages = with pkgs; [
    rofi
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

    blueman
    google-chrome
    # Sách: foliate đọc epub/mobi/azw3/fb2/cbz/opds (typography tốt hơn calibre
    # đã gỡ; thư viện ở ~/Books/{Textbooks,Reading}).
    foliate
    imv # xem ảnh (nhẹ, có zoom/timeline)
    mpv # xem video/nhạc
    ripgrep # tìm nội dung nhanh (thay grep)
    fd # tìm file nhanh (thay find)
    sioyek
    obsidian
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
    # Máy ảo — luyện cài máy mới (docs/06).
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
