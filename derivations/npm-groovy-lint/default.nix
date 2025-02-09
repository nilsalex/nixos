{
  pkgs ? import <nixpkgs> { },
}:

pkgs.buildNpmPackage rec {
  pname = "npm-groovy-lint";
  version = "14.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "nvuillam";
    repo = "npm-groovy-lint";
    rev = "v${version}";
    hash = "sha256-YnCsy9VC++UjlehLZpfQ9oIPqMG782tzLIoEhY50HUc=";
  };

  npmDepsHash = "sha256-muEAhi7pnhZUCrW/fOKRPkEDCLhAGKN/AH3rlPaLrGM=";

  npmPackFlags = [ "--ignore-scripts" ];

  meta = {
    description = "npm-groovy-lint";
    homepage = "https://github.com/nvuillam/npm-groovy-lint";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.linux;
  };
}
