{ llm-agents, ... }:
{
  nixpkgs.overlays = [
    llm-agents.overlays.shared-nixpkgs
  ];
}
