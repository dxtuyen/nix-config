{ pkgs, ... }:

# Starship prompt — phong cách rice cộng đồng:
# chỉ hiện đường dẫn + git + thời gian lệnh chạy lâu + ký tự ❯.
# KHÔNG có user@hostname như bash mặc định.

{
  programs.starship = {
    enable = true;
    # Tự tích hợp vào programs.bash (đã bật ở default.nix)
    enableBashIntegration = true;

    settings = {
      # 1 dòng trống giữa các prompt — đây là MẶC ĐỊNH của Starship,
      # cần cho prompt 2 dòng để có khoảng thở giữa các lần gõ lệnh
      add_newline = true;

      # Prompt 2 dòng kiểu rice cộng đồng:
      # dòng 1 — đường dẫn + branch + git status + thời gian lệnh
      # dòng 2 — chỉ có ❯ và chỗ gõ lệnh
      format = "$directory$git_branch$git_status$cmd_duration\n$character";

      directory = {
        # Tokyo Night blue
        style = "bold #7aa2f7";
        read_only_style = "#f7768e";
        truncation_length = 3;
        truncate_to_repo = true;
        home_symbol = "~";
        format = "[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        symbol = "";
        style = "#bb9af7";
        format = "[$symbol$branch]($style) ";
      };

      # Git status kiểu Nerd Font icons, màu Tokyo Night
      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "#565f89";

        modified = "[✱](#e0af68)"; # file sửa — vàng
        deleted = "[✖](#f7768e)"; # file xoá — đỏ
        untracked = "[?](#7aa2f7)"; # file mới — xanh dương
        renamed = "[»](#bb9af7)"; # đổi tên — tím
        conflicted = "[=](#f7768e)"; # conflict khi merge — đỏ

        # Ẩn các trạng thái ít khi cần cho gọn prompt
        stashed = "";
        ahead = "";
        behind = "";
        diverged = "";
        typechanged = "";
      };

      cmd_duration = {
        min_time = 2000; # Chỉ hiện khi lệnh chạy ≥ 2s
        style = "#e0af68";
        format = "[ $duration]($style) ";
      };

      character = {
        success_symbol = "[❯](bold #9ece6a)";
        error_symbol = "[❯](bold #f7768e)";
        vicmd_symbol = "[❮](bold #73daca)";
      };
    };
  };
}
