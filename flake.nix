{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "git+ssh://git@github.com/NixOs/nixpkgs?ref=nixos-unstable";
    home-manager.url = "git+ssh://git@github.com/nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-config.url = "git+ssh://git@github.com/nilsalex/kickstart.nvim?ref=fork";
  };

  outputs = { self, nixpkgs, home-manager, neovim-config, ... }@attrs:
    let mkHost = { hostname, hardwareConfig }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          (import ./configuration.nix { inherit hostname hardwareConfig; } )
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nils = { pkgs, ... }: {
              imports = [
	        neovim-config.homeManagerModules.neovim
                ./home.nix
              ];
            };
          }
        ];
     };
     in {
       nixosConfigurations = {
         linux = mkHost { hostname = "linux"; hardwareConfig = ./hosts/linux/hardware-configuration.nix; };
         alexntng = mkHost { hostname = "alexntng"; hardwareConfig = ./hosts/alexntng/hardware-configuration.nix; };
       };
     };
}
