{ ... }:

# Git identity cho máy mới (tự có sau nixos-install, khỏi `git config` tay).
{
  programs.git = {
    enable = true;

    # Thay cho extraConfig (đã deprecated ở HM mới).
    settings = {
      user = {
        name = "dxtuyen";
        email = "tuyendoxuan05@gmail.com";
      };

      init.defaultBranch = "main";
      pull.rebase = true; # lịch sử phẳng
      core = {
        pager = "cat"; # không mở less khi diff/log
        editor = "nvim";
      };
    };
  };
}
