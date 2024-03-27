{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation rec {
  name = "inkscape-silhouette-${version}";
  version = "v1.28";

  src = pkgs.fetchFromGitHub {
    owner = "fablabnbg";
    repo = "inkscape-silhouette";
    rev = "${version}";
    hash = "sha256-uNVhdkZFadL7QNlCsXq51TbhzRKH9KYDPDNCFhw3cQs=";
  };

  buildInputs = [ pkgs.gettext ];

  installPhase = ''
    PREFIX=/ make install DESTDIR=$out
  '';
}
