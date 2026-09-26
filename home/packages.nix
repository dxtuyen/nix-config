{ pkgs, ... }:

# Gói user: stable (pinned trong flake.lock). TickTick dùng bản web/PWA (xem docs/02).
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
    networkmanagerapplet
    blueman
    google-chrome
    # trash-cli: plugin `recycle-bin` của yazi gọi lệnh `trash-list` /
    # `trash-restore` / `trash-rm` / `trash-empty`. Không có gói này thì plugin
    # báo "trashcli not found".
    trash-cli
    # 📖 Sách: foliate đọc epub/mobi/azw3/fb2/cbz/opds (WebKitGTK → typography
    # đẹp hơn hẳn calibre-ebook-viewer). Thư viện nằm ở ~/Books/{Textbooks,Reading}
    # — KHÔNG dùng calibre nữa (đã gỡ), nên không có `ebook-convert` chuyển đổi:
    # tải sách nên chọn thẳng định dạng epub/pdf.
    foliate
    imv # xem ảnh (nhẹ, có zoom/timeline)
    mpv # xem video/nhạc
    ripgrep # tìm nội dung nhanh (thay grep)
    fd # tìm file nhanh (thay find)
    zoxide # nhớ thư mục hay đi, `z <tên>` nhảy thẳng tới (khởi tạo ở home/default.nix)
    sioyek
    obsidian
    jq
    fastfetch
    libreoffice
    # Dev: thư viện để per-project (venv / `nix develop`), không cài global.
    vscode
    python3
    python3Packages.virtualenv
    direnv # tu kich hoat moi truong nix-shell khi cd vao folder co .envrc
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
