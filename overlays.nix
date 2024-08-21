{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      clamav = prev.clamav.overrideAttrs (old: rec {
        version = "1.4.0";
        src = pkgs.fetchurl {
          url = "https://www.clamav.net/downloads/production/${old.pname}-${version}.tar.gz";
          hash = "sha256-1nqymeXKBdrT2imaXqc9YCCTcqW+zX8TuaM8KQM4pOY=";
        };
      });
    })
  ];
}
