{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "github:nilsalex/kickstart.nvim/fork-v2";
  };

  outputs = { self, nixpkgs, home-manager, neovim-config, ... }@attrs:
    let
      mkHost = { hostname, hardwareConfig }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs;
          modules = [
            ({ config, pkgs, ... }:

              let
                overlays = [
                  (final: prev: {
                    clamav = prev.clamav.overrideAttrs (old: rec {
                      version = "1.4.0";
                      src = pkgs.fetchurl {
                        url =
                          "https://www.clamav.net/downloads/production/${old.pname}-${version}.tar.gz";
                        hash =
                          "sha256-1nqymeXKBdrT2imaXqc9YCCTcqW+zX8TuaM8KQM4pOY=";
                      };
                    });
                  })
                ];
              in { nixpkgs.overlays = overlays; })
            (import ./configuration.nix { inherit hostname hardwareConfig; })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.nils = { pkgs, ... }: {
                imports =
                  [ neovim-config.homeManagerModules.neovim ./home.nix ];
              };
            }
          ];
        };
    in {
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
