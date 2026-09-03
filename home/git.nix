{ ... }:

# Cấu hình Git của user — quản lý qua home-manager để máy mới
# (sau nixos-install) TỰ CÓ identity + tuỳ chọn, không phải gõ lại
# `git config --global` bằng tay (xem docs/03 Bước 10).
#
# Lưu ý: gói `git` vẫn nằm trong environment.systemPackages
# (modules/nixos/core.nix) để dùng được ở tầng hệ thống;
# programs.git ở đây chỉ thêm file config + lệnh git cho user.

{
  programs.git = {
    enable = true;

    # Identity commit — khớp với tài khoản GitHub `dxtuyen`
    settings.user = {
      name = "dxtuyen";
      email = "tuyendoxuan05@gmail.com";
    };

    extraConfig = {
      init.defaultBranch = "main"; # nhánh mặc định khi git init
      pull.rebase = true; # git pull luôn rebase — lịch sử phẳng
      core = {
        pager = "cat"; # không mở less khi git diff/log
        editor = "nvim"; # editor cho git commit -v, rebase...
      };
    };
  };
}
