{ inputs, userName, ... }:

# Điểm nhập chính của Home Manager cho user — mọi module trong home/ import ở đây.
# Hệ thống chạy nixos-unstable nên các module lấy gói trực tiếp từ `pkgs`.

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
    inputs.nixvim.homeModules.nixvim
    ./config
    ./apps
    ./script
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

  # CLI fzf độc lập cho terminal; HM cũng bật Ctrl-R tìm lịch sử Bash.
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # Nơi duy nhất thêm ~/.local/bin vào PATH + tạo ~/.bashrc.
  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"

      # Foot dùng OSC 7 để mở terminal mới tại thư mục hiện tại; OSC 2 đặt title.
      __foot_escape_uri_path() {
        local LC_ALL=C
        local path="$1" escaped="" char hex
        while [ -n "$path" ]; do
          char="''${path:0:1}"
          path="''${path:1}"
          case "$char" in
            [a-zA-Z0-9/._~-]) escaped+="$char" ;;
            *) printf -v hex '%%%02X' "'$char"; escaped+="$hex" ;;
          esac
        done
        __foot_osc7_path="$escaped"
      }

      __set_window_title() {
        # Tách 2 bước để né tilde expansion (title hiện full path).
        local dir="''${PWD/#$HOME/}"
        printf '\033]2;~%s\007' "$dir"
        __foot_escape_uri_path "$PWD"
        printf '\033]7;file://%s%s\033\\' "''${HOSTNAME:-localhost}" "$__foot_osc7_path"
      }
      PROMPT_COMMAND="__set_window_title''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

      # nt: cùng project → tmux window mới; ngoài tmux → cửa sổ Foot mới.
      nt() {
        if [ -n "''${TMUX:-}" ]; then
          tmux new-window -c "$PWD"
        else
          foot --working-directory "$PWD" >/dev/null 2>&1 &
          disown
        fi
      }

      # y: mở yazi, thoát ra (`q`) thì shell cd theo thư mục cuối cùng đứng trong
      # yazi (yazi ghi nó vào --cwd-file). Bổ sung cho phím `b`/`B` trong yazi —
      # chúng đi hướng NGƯỢC (yazi → shell), còn hàm này đi hướng shell → yazi →
      # shell. Cố ý viết thủ công thay vì `programs.yazi.enableBashIntegration`:
      # module đó kéo theo finalPackage override (xem home/apps/yazi.nix).
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
