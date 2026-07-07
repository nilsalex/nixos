{ llm-agents, crit, ... }:
{
  nixpkgs.overlays = [
    llm-agents.overlays.default
    (
      final: prev:
      {
        crit = crit.packages.${final.stdenv.hostPlatform.system}.default;
      }
    )
    (
      final: prev:
      {
        xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            (builtins.toFile "bump-buffers.patch" ''
              --- a/include/pipewire_screencast.h
              +++ b/include/pipewire_screencast.h
              @@ -6,3 +6,3 @@
              -#define XDPW_PWR_BUFFERS 2
              -#define XDPW_PWR_BUFFERS_MIN 2
              +#define XDPW_PWR_BUFFERS 4
              +#define XDPW_PWR_BUFFERS_MIN 4
               #define XDPW_PWR_ALIGN 16
            '')
          ];
        });
      }
    )
  ];
}
