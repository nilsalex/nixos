{ pkgs ? import <nixpkgs> { } }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "yktotp-jsonapi";
  version = "0.1.0-alpha";

  src = pkgs.fetchFromGitHub {
    owner = "nilsalex";
    repo = pname;
    rev = "1455d310e76bed2e8f593e35c4516b9e6730d665";
    hash = "sha256-Bj1M0lVtbulpnhVrhExnT4KuWO9QBJUsMHfRvxwCJ6c=";
  };

  cargoHash = "sha256-SFcGItpN3wP3MREXGxS1h0lwQPTHfFYKVzaRdAQIauI=";

  buildInputs = [ pkgs.pcsclite ];

  nativeBuildInputs = [ pkgs.pkg-config ];

  meta = { };
}
