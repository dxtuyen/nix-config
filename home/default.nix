{ inputs, userName, ... }:

# Main Home Manager entry point for this user.

{
  home = {
    username = userName;
    homeDirectory = "/home/${userName}";
    stateVersion = "26.05";
  };

  # Standard XDG directories.
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      # null disables management of the directory.
      templates = null;
      projects = null;
    };
  };

  imports = [
    inputs.nixvim.homeModules.nixvim
    ./config
    ./apps
    ./scripts
  ];

  programs.home-manager.enable = true;

  # Configure shell integrations through Home Manager.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Cache development environments.
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  # Enable fzf and Bash history search.
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # Add user scripts to PATH and configure Bash.
  programs.bash = {
    enable = true;
    shellAliases.nswitch = ''cd "$HOME/nix-config" && sudo nixos-rebuild switch --flake ".#$(hostname -s)"'';
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"

      # OSC 7 sets the working directory; OSC 2 sets the terminal title.
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
        # Set the terminal title and working-directory metadata.
        local dir="''${PWD/#$HOME/}"
        printf '\033]2;~%s\007' "$dir"
        __foot_escape_uri_path "$PWD"
        printf '\033]7;file://%s%s\033\\' "''${HOSTNAME:-localhost}" "$__foot_osc7_path"
      }
      PROMPT_COMMAND="__set_window_title''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

      # Open a new tmux window or Foot terminal in the current directory.
      nt() {
        if [ -n "''${TMUX:-}" ]; then
          tmux new-window -c "$PWD"
        else
          foot --working-directory "$PWD" >/dev/null 2>&1 &
          disown
        fi
      }

      # Open Yazi and change to its last directory on exit.
      # Kept custom to avoid Home Manager's Yazi package override.
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
