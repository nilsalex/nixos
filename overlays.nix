{ pkgs-stable, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      freeplane = pkgs-stable.freeplane;
    })
  ];
}
