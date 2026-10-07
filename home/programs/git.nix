{ ... }:

# Git identity for a fresh machine (comes with nixos-install, no manual `git config`).
{
  programs.git = {
    enable = true;

    # Replaces extraConfig (deprecated in new Home Manager).
    settings = {
      user = {
        name = "dxtuyen";
        email = "tuyendoxuan05@gmail.com";
      };

      init.defaultBranch = "main";
      pull.rebase = true; # linear history
      core = {
        pager = "cat"; # no less for diff/log
        editor = "nvim";
      };
    };
  };
}
