{
  description = "NixOS system configuration";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/release-23.05;
  };

  outputs = { self, nixpkgs, ... }@attrs: {
    nixosConfigurations.alexntng = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./configuration.nix ];
    };
  };
}
