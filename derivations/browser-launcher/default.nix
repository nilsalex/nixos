{ pkgs }:

let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.requests ]);
in
pkgs.stdenv.mkDerivation {
  pname = "browser-launcher";
  version = "1.0.0";
  src = ./src;

  installPhase = ''
    mkdir -p $out/bin
    cp browser-launcher.py $out/bin/browser-launcher
    chmod +x $out/bin/browser-launcher
    substituteInPlace $out/bin/browser-launcher \
      --replace-fail "#!/usr/bin/env python3" "#!${pythonEnv}/bin/python3"
  '';
}
