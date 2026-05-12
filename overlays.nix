{ llm-agents, crit, ... }:
{
  nixpkgs.overlays = [
    llm-agents.overlays.default
    (
      final: prev:
      {
        crit = crit.packages.${final.system}.default;
      }
    )
  ];
}
