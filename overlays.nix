{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      freeplane = pkgs.freeplane;
    })
  ];
}
