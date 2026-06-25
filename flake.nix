{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "github:nilsalex/kickstart.nvim/fork-v2-rebased";
    llm-agents.url = "github:numtide/llm-agents.nix";
    crit.url = "github:tomasz-tomczyk/crit";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      neovim-config,
      llm-agents,
      ...
    }@attrs:
    let
      mkHost =
        { hostname, hardwareConfig }:
        nixpkgs.lib.nixosSystem {
          specialArgs = attrs;
          modules = [
            (import ./overlays.nix)
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
                    ./modules/opencode.nix
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
