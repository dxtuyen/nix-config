{ pkgs, ... }:

# Starship: chỉ đường dẫn + git + lệnh chạy lâu + ký tự ❯.

{
  programs.starship = {
    enable = true;
    # Tích hợp bash (đã bật ở default.nix).
    enableBashIntegration = true;

    settings = {
      # Dòng trống giữa các prompt (mặc định Starship).
      add_newline = true;

      # Dòng 1: đường dẫn + git + thời gian lệnh; dòng 2: ❯.
      format = "$directory$git_branch$git_status$cmd_duration\n$character";

      directory = {
        # Catppuccin Mocha blue
        style = "bold #89b4fa";
        read_only_style = "#f38ba8";
        truncation_length = 3;
        truncate_to_repo = true;
        home_symbol = "~";
        format = "[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        symbol = "";
        style = "#cba6f7";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "#6c7086";

        modified = "[✱](#fab387)";
        deleted = "[✖](#f38ba8)";
        untracked = "[?](#89b4fa)";
        renamed = "[»](#cba6f7)";
        conflicted = "[=](#f38ba8)";

        # Ẩn trạng thái ít dùng cho gọn prompt.
        stashed = "";
        ahead = "";
        behind = "";
        diverged = "";
        typechanged = "";
      };

      cmd_duration = {
        min_time = 2000; # chỉ hiện khi lệnh chạy ≥ 2s
        style = "#fab387";
        format = "[ $duration]($style) ";
      };

      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
        vicmd_symbol = "[❮](bold #94e2d5)";
      };
    };
  };
}
