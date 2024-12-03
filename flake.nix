{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "github:nilsalex/kickstart.nvim/fork-v2";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      neovim-config,
      nix-ld,
      ...
    }@attrs:
    let
      mkHost =
        { hostname, hardwareConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs;
          modules = [
            nix-ld.nixosModules.nix-ld
            (import ./overlays.nix)
            (import ./configuration.nix { inherit hostname hardwareConfig; })
            { programs.nix-ld.dev.enable = true; }
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
