{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      bun = prev.bun.overrideAttrs (oldAttrs: rec {
        version = "1.3.10";
        sources = {
          "aarch64-darwin" = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-aarch64.zip";
            hash = "sha256-ggNOh8nZtDmOphmu4u7V0qaMgVfppq4tEFLYTVM8zY0=";
          };
          "aarch64-linux" = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-aarch64.zip";
            hash = "sha256-+l7LJcr6jo9ch6D4M3GdRt0K8KhseDfYBlMSEtVWNtM=";
          };
          "x86_64-darwin" = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-x64-baseline.zip";
            hash = "sha256-+WhsTk52DbTN53oPH60F5VJki5ycv6T3/Jp+wmufMmc=";
          };
          "x86_64-linux" = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
            hash = "sha256-9XvAGH45Yj3nFro6OJ/aVIay175xMamAulTce3M9Lgg=";
          };
        };
        src = sources.${prev.stdenvNoCC.hostPlatform.system};
      });
    })
  ];
}
