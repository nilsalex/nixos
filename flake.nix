{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@attrs: 
    let mkHost = { hostname, hardwareConfig }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          (import ./configuration.nix { inherit hostname hardwareConfig; } )
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.nils = import ./home.nix;
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
