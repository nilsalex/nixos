{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOs/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "github:nilsalex/kickstart.nvim/fork-v2";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      neovim-config,
      ...
    }@attrs:
    let
      mkHost =
        { hostname, hardwareConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs;
          modules = [
            (import ./overlays.nix {
              pkgs-stable = nixpkgs-stable.legacyPackages.x86_64-linux;
            })
            (import ./configuration.nix { inherit hostname hardwareConfig; })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nils =
                { pkgs, ... }:
                {
                  imports = [
                    neovim-config.homeManagerModules.neovim
                    ./home.nix
                  ];
                };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        linux = mkHost {
          hostname = "linux";
          hardwareConfig = ./hosts/linux/hardware-configuration.nix;
        };
        alexntng = mkHost {
          hostname = "alexntng";
          hardwareConfig = ./hosts/alexntng/hardware-configuration.nix;
        };
      };
    };
}
