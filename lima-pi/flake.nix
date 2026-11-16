{
  description = "Lima NixOS VM with the pi coding agent wired to the litellm proxy";

  inputs = {
    nixos-lima.url = "github:nixos-lima/nixos-lima";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      nixpkgs,
      nixos-lima,
      llm-agents,
      ...
    }:
    let
      system = "x86_64-linux";
      vm = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit llm-agents; };
        modules = [
          {
            nixpkgs.hostPlatform = system;
          }
          "${nixos-lima}/lima.nix"
          ./vm.nix
        ];
      };
    in
    {
      # nix build .#img --out-link result-vm   →   result-vm/nixos.qcow2
      packages.${system}.img = vm.config.system.build.images.qemu-efi;

      # Push updates from the host (the guest never needs this flake):
      #   limactl show-ssh <name>                    # connection details for ~/.ssh/config
      #   nixos-rebuild switch --flake .#vm --target-host <name> --use-remote-sudo
      nixosConfigurations.vm = vm;
    };
}
