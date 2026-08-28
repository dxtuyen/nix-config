{
  description = "Doxuan Tuyen's reproducible NixOS laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Phương án nixpkgs-unstable: dùng riêng cho vài gói cần phiên bản mới hơn
    # stable (vd: ticktick thường phát hành bản chính thức sớm hơn bản được
    # đóng gói vào nhánh nixos-26.05). Chỉ "chấm" từng gói từ đây, phần còn
    # lại của hệ thống vẫn chạy trên nixpkgs stable.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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
          inherit inputs;
          userName = "doxuantuyen";
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/laptop
        ];
      };
    };
}
