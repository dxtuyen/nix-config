{ pkgs, userName, ... }:

# Điểm nhập chính của Home Manager cho user.
# Mọi module trong thư mục home/ đều được import ở đây.

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";
  };

  # XDG bật một lần ở đây; module con chỉ khai nội dung.
  xdg.enable = true;

  imports = [
    ./packages.nix
    ./git.nix
    ./alacritty.nix
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
  ];

  programs.home-manager.enable = true;

  # Nơi duy nhất thêm ~/.local/bin vào PATH + tạo ~/.bashrc.
  programs.bash = {
    enable = true;
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"

      # direnv: tu kich hoat moi truong nix-shell khi cd vao folder co .envrc
      eval "$(direnv hook bash)"

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
