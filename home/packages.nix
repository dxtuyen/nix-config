{ pkgs, ... }:

# Ghi chú: toàn bộ gói bên dưới lấy từ nixpkgs stable (pinned nixos-26.05
# trong flake.lock). Trước đây `ticktick` phải lấy từ nixpkgs-unstable vì
# bản stable đóng gói chậm — hiện stable đã đuổi kịp nên không cần nữa.
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
    # TickTick — stable 26.05 đã đóng gói đúng bản chính thức mới nhất (8.0.10)
    ticktick

    # Máy ảo — luyện tập cài máy mới theo docs/06-Luyen-Tap-VM.md
    # qemu_kvm: bản QEMU chỉ target x86_64 + KVM, nhẹ hơn meta-package qemu
    qemu_kvm
    qemu-utils
    OVMF
  ];
}
