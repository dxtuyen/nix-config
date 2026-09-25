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
    calibre
    sioyek
    obsidian
    anki
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
