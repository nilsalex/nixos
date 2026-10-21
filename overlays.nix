{ llm-agents, ... }:
{
  nixpkgs.overlays = [
    llm-agents.overlays.shared-nixpkgs

    # Waybar from git master: niri module features (workspace-taskbar,
    # window-rewrite, hide-empty, enable-bar-scroll, ...) are newer than the
    # 0.15.0 release in nixpkgs.
    (final: prev: {
      waybar = prev.waybar.overrideAttrs (old: {
        version = "0.16.0-unstable-2026-10-10";
        src = final.fetchFromGitHub {
          owner = "Alexays";
          repo = "Waybar";
          rev = "4e207a0cb51a9eb89b4245d90245721f5e39bf06";
          hash = "sha256-0L1elPWYo9yKgEwpXWWVWQyPVU0SW36LkWUR26CksgU=";
        };
        buildInputs = old.buildInputs ++ [ final.modemmanager ];
        # cava module disabled: master's zero-initialized cava backend is
        # buggy (renderer lives on; revisit on a release > 0.15.0)
        mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dcava=disabled" ];
        # master still reports "Waybar v0.15.0" from git-describe
        doInstallCheck = false;
      });
    })

    # v4l2loopback: pass INSTALL_MOD_PATH via installFlags with DEPMOD=true
    # instead of patching the Makefile — fixes the modules.devname conflict
    # (nixpkgs#575851, nixpkgs PR #575861). Drop once nixos-unstable has it.
    (final: prev: {
      linuxPackages = prev.linuxPackages.extend (_: lprev: {
        v4l2loopback = lprev.v4l2loopback.overrideAttrs (old: {
          preBuild = builtins.replaceStrings
            [
              ''substituteInPlace Makefile --replace-fail "modules_install" "INSTALL_MOD_PATH=$out modules_install"''
            ]
            [ "" ]
            old.preBuild;
          installFlags = [
            "DEPMOD=true"
            "INSTALL_MOD_PATH=${placeholder "out"}"
          ];
        });
      });
    })
  ];
}
