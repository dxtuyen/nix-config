{
  pkgs,
  userName,
  ...
}:

# Điểm nhập chính của Home Manager cho user — mọi module trong home/ import ở đây.
# Hệ thống chạy nixos-unstable nên gói lấy thẳng từ `pkgs`.

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
      # null = không quản lý (không tạo, không có trong user-dirs.dirs).
      templates = null; # ~/Templates — không dùng
      projects = null; # ~/Projects — không dùng
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

  # Tích hợp shell qua Home-Manager module (tự hook vào bash).
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
        # Tách 2 bước để né tilde expansion (title hiện full path).
        local dir="''${PWD/#$HOME/}"
        printf '\033]2;~%s\007' "$dir"
      }
      PROMPT_COMMAND="__set_window_title''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

      # y: mở yazi, thoát ra (`q`) thì shell cd theo thư mục cuối cùng đứng trong
      # yazi (yazi ghi nó vào --cwd-file). Bổ sung cho phím `b`/`B` trong yazi —
      # chúng đi hướng NGƯỢC (yazi → shell), còn hàm này đi hướng shell → yazi →
      # shell. Cố ý viết thủ công thay vì `programs.yazi.enableBashIntegration`:
      # module đó kéo theo finalPackage override (xem home/yazi.nix).
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };
}
