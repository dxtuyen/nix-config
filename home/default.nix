{
  pkgs,
  unstablePkgs,
  userName,
  ...
}:

# Điểm nhập chính của Home Manager cho user.
# Mọi module trong thư mục home/ đều được import ở đây.
#
# `unstablePkgs` là bộ gói từ nixos-unstable (xem `flake.nix`) — CHỈ `home/yazi.nix`
# dùng tới, để lấy yazi mới hơn bản trong nixpkgs ổn định.

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";
  };

  # XDG base directories + user directories chuẩn.
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true; # Tự động tạo thư mục khi switch / cài máy mới
    };
  };

  imports = [
    ./packages.nix
    ./git.nix
    ./foot.nix
    ./mimeapps.nix
    ./starship.nix
    ./gtk.nix
    ./sway.nix
    ./waybar.nix
    ./mako.nix
    ./fcitx5.nix
    ./scripts.nix
    ./sioyek.nix
    ./pomodoro.nix
    ./remnote.nix
    ./thunar.nix
    ./yazi.nix
  ];

  programs.home-manager.enable = true;

  # Tích hợp công cụ shell qua Home-Manager module (tự hook vào bash và quản lý chuẩn).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Cache nix-shell/flake environment, vào thư mục dev tức thì
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # Nơi duy nhất thêm ~/.local/bin vào PATH + tạo ~/.bashrc.
  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"

      # Starship không set title nên tự phát OSC 2 mỗi prompt.
      __set_window_title() {
        # Tách 2 bước để né tilde expansion làm title hiện full path.
        local dir="''${PWD/#$HOME/}"
        printf '\033]2;~%s\007' "$dir"
      }
      PROMPT_COMMAND="__set_window_title''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    '';
  };
}
