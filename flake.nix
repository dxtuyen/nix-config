{
  description = "Doxuan Tuyen's reproducible NixOS laptop";

  inputs = {
    # Rolling release (nixos-unstable), gate bởi test suite + rollback
    # generation trivial — theo trick "Use NixOS-unstable" của matklad.
    # Unstable là misnomer: thực chất là continuous release khá ổn định.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # HM phát triển trên nixpkgs-unstable nên dùng thẳng master
    # để khỏi lệch module/packages.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixvim's Home Manager module manages both the Neovim package and config.
    # Keep its own nixpkgs input: Nixvim recommends against following ours.
    nixvim.url = "git+https://github.com/nix-community/nixvim";
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
