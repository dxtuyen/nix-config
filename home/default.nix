{ pkgs, userName, ... }:

# Điểm nhập chính của Home Manager cho user.
# Mọi module trong thư mục home/ đều được import ở đây.

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";

    # LƯU Ý: PATH cho ~/.local/bin được quản lý ở programs.bash bên dưới
    # (không dùng sessionPath nữa để tránh quản lý 2 nơi).
  };

  imports = [
    ./packages.nix # Các gói cài qua home.packages
    ./foot.nix # Terminal foot (theme Tokyo Night)
    ./gtk.nix # Cấu hình GTK: icon Papirus-Dark + dark theme mặc định
    ./sway.nix # Cấu hình Sway (window manager)
    ./waybar.nix # Thanh trạng thái Waybar
    ./mako.nix # Trình thông báo Mako
    ./fcitx5.nix # Bộ gõ tiếng Việt Fcitx5
    ./scripts.nix # Các script thủ công trong ~/.local/bin
    ./remnote.nix # Tích hợp RemNote AppImage (appimage-run + desktop entry + update-remnote)
  ];

  # Quản lý profile home-manager (cho phép lệnh home-manager switch)
  programs.home-manager.enable = true;

  # Kích hoạt bash + tạo file ~/.bashrc.
  # Đây là NƠI DUY NHẤT quản lý PATH cho ~/.local/bin (nơi các script thủ công
  # như update-remnote, lock-screen, quick-lang... được cài vào).
  # NixOS mặc định không có ~/.bashrc, nên cần programs.bash để tạo ra nó.
  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
