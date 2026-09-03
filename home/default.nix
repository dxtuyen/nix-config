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

  # Nền tảng XDG: bật MỘT LẦN duy nhất tại entry point,
  # để module con (remnote, thunar...) chỉ khai báo nội dung
  # qua xdg.configFile / xdg.desktopEntries mà không phải tự bật.
  xdg.enable = true;

  imports = [
    ./packages.nix # Các gói cài qua home.packages
    ./git.nix # Git identity + tuỳ chọn (máy mới tự có user.email, không gõ tay)
    ./alacritty.nix # Terminal Alacritty (theme Tokyo Night)
    ./starship.nix # Prompt tối giản không user@hostname
    ./gtk.nix # Cấu hình GTK: icon Papirus-Dark + dark theme mặc định
    ./sway.nix # Cấu hình Sway (window manager)
    ./waybar.nix # Thanh trạng thái Waybar
    ./mako.nix # Trình thông báo Mako
    ./fcitx5.nix # Bộ gõ tiếng Việt Fcitx5
    ./scripts.nix # Các script thủ công trong ~/.local/bin
    ./pomodoro.nix # Pomodoro timer + menu (tách riêng cho gọn)
    ./remnote.nix # Tích hợp RemNote AppImage (appimage-run + desktop entry + update-remnote)
    ./thunar.nix # Đăng ký Alacritty làm terminal mặc định cho Thunar
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

      # Đặt tiêu đề cửa sổ theo thư mục hiện tại (Waybar + rofi đọc từ đây).
      # Starship không tự set terminal title như PROMPT_COMMAND mặc định
      # của bash, nên cần tự phát OSC 2 mỗi lần hiện prompt.
      __set_window_title() {
        # Tách 2 bước để né tilde expansion: nếu viết trực tiếp
        # PWD/#HOME/~ trong replacement thì ký tự ~ bị bash mở rộng
        # ngược thành $HOME, làm title vẫn hiện đường dẫn đầy đủ.
        local dir="''${PWD/#$HOME/}"
        printf '\033]2;~%s\007' "$dir"
      }
      PROMPT_COMMAND="__set_window_title''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    '';
  };
}
