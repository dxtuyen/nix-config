{
  description = "Doxuan Tuyen's reproducible NixOS laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # ⭐ Chỉ dùng để lấy `yazi` + `yaziPlugins` mới hơn nixpkgs ổn định.
    # Lý do: nixpkgs 26.05 đóng gói yazi 26.5.6 — bản này chưa có "Trash bin"
    # (scheme `trash://`). Bên trong thùng rác, `d` sẽ GHI LẠI vào thùng rác
    # (thành `X.2`, `X.2.2`, ... thay vì xoá), còn `D` xoá vĩnh viễn thì để
    # lại file `.trashinfo` mồ côi. Bản 26.9.1 đã sửa cả hai.
    # ⚠️ CHỈ override yazi, KHÔNG đụng gói khác — phần còn lại hệ thống vẫn
    # chạy nixpkgs 26.05. Xem `home/yazi.nix` chỗ dùng.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Gói lấy từ unstable — xem chú thích ở `inputs` phía trên.
      unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      formatter.${system} = pkgs.writeShellApplication {
        name = "nixfmt";
        text = ''
          ${pkgs.findutils}/bin/find . -type f -name '*.nix' -print0 \
            | ${pkgs.findutils}/bin/xargs --no-run-if-empty -0 ${pkgs.nixfmt}/bin/nixfmt "$@"
        '';
      };

      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs unstablePkgs;
          userName = "doxuantuyen";
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/laptop
        ];
      };
    };
}
