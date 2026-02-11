{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "github:nilsalex/kickstart.nvim/fork-v2";
    opencode.url = "github:anomalyco/opencode";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      neovim-config,
      opencode,
      ...
    }@attrs:
    let
      mkHost =
        { hostname, hardwareConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs;
          modules = [
            (import ./overlays.nix)
            {
              nixpkgs.overlays = [
                (final: prev: {
                  opencode = opencode.packages.${prev.stdenv.hostPlatform.system}.default;
                })
              ];
            }
            (import ./configuration.nix { inherit hostname hardwareConfig; })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit opencode; };
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
