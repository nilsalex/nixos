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
    (final: prev: {
      awscli2 = prev.awscli2.overrideAttrs (old: {
        patches = [
          # Temporary test fix until https://github.com/aws/aws-cli/pull/8838 is merged upstream
          (pkgs.fetchpatch {
            url = "https://github.com/aws/aws-cli/commit/b5f19fe136ab0752cd5fcab21ff0ab59bddbea99.patch";
            hash = "sha256-NM+nVlpxGAHVimrlV0m30d4rkFVb11tiH8Y6//2QhMI=";
          })
        ];
      });
    })
  ];
}
