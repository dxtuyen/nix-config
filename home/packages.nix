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
    libnotify
    pavucontrol
    brightnessctl
    translate-shell
    goldendict-ng
    thunar
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
    unrar
    # Dev: thư viện để per-project (venv / `nix develop`), không cài global.
    vscode
    python3
    python3Packages.virtualenv
    gcc
    gnumake
    cmake
    gdb
    distrobox
    # Máy ảo — luyện cài máy mới (docs/06).
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
