{
  config,
  lib,
  pkgs,
  llm-agents,
  ...
}:

let
  # the real pi stays in the store; the wrapper on PATH is what the user runs
  piPkg = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  # `pi` on PATH = the real pi + environment for the litellm discovery
  # extension (see litellm.ts), which registers the provider and fetches
  # the model catalog itself. Set PI_LITELLM_BUCKET to use a different
  # upstream bucket (key file, catalog and key env var derive from the
  # bucket name).
  piWrapped = pkgs.writeShellScriptBin "pi" ''
    set -euo pipefail

    curl="${lib.getExe pkgs.curl}"
    jq="${lib.getExe pkgs.jq}"
    cat="${pkgs.coreutils}/bin/cat"
    mkdir="${pkgs.coreutils}/bin/mkdir"
    rm="${pkgs.coreutils}/bin/rm"
    tr="${pkgs.coreutils}/bin/tr"
    ip="${pkgs.iproute2}/bin/ip"
    awk="${pkgs.gawk}/bin/awk"

    export PI_CODING_AGENT_DIR="$HOME/.pi"
    export PI_OFFLINE=1

    bucket="''${PI_LITELLM_BUCKET:-personal}"
    keyvar="LITELLM_KEY_$(printf %s "$bucket" | $tr 'a-z-' 'A-Z_')"
    keyfile="/var/lib/litellm/$bucket.key"
    if [ -z "''${!keyvar:-}" ] && [ -s "$keyfile" ]; then
      export "$keyvar"="$($cat "$keyfile")"
    fi

    proxy=""
    for cand in "host.lima.internal" "$($ip route 2>/dev/null | $awk '/^default/ {print $3; exit}')" "192.168.5.2" "127.0.0.1"; do
      [ -n "$cand" ] || continue
      if $curl -fsS -m 2 "http://$cand:4000/health/liveliness" >/dev/null 2>&1; then
        proxy="http://$cand:4000"
        break
      fi
    done
    if [ -z "$proxy" ]; then
      if [ -f "$PI_CODING_AGENT_DIR/extensions/litellm.ts" ]; then
        echo "pi: litellm proxy not reachable, starting with existing $PI_CODING_AGENT_DIR config" >&2
        exec ${lib.getExe piPkg} "$@"
      fi
      echo "pi: no litellm proxy found (host.lima.internal, default gateway, 192.168.5.2, 127.0.0.1)" >&2
      exit 1
    fi

    if [ -z "''${!keyvar:-}" ]; then
      echo "pi: no key ($keyvar or $keyfile)" >&2
    fi
    export LITELLM_KEY="''${!keyvar:-}"
    export LITELLM_BASE="$proxy/v1"
    export LITELLM_MODELS="$proxy/upstream/$bucket/v1/models"

    # the litellm provider extension discovers models at startup and on
    # refresh; models.json was our hand-rolled snapshot of the same data,
    # so remove it if an older wrapper version left one behind
    $mkdir -p "$PI_CODING_AGENT_DIR/extensions"
    rm -f "$PI_CODING_AGENT_DIR/models.json"
    $cat ${./litellm.ts} > "$PI_CODING_AGENT_DIR/extensions/litellm.ts"

    # seed settings once so a fresh home directory starts on the litellm
    # provider; /model + Ctrl+S afterwards owns the default model
    if [ ! -s "$PI_CODING_AGENT_DIR/settings.json" ]; then
      first=$($curl -fsS -m 10 -H "Authorization: Bearer $LITELLM_KEY" \
        "$LITELLM_MODELS" 2>/dev/null \
        | $jq -r 'try ([.data[]
                    | select(.architecture.modality == "text->text")
                    | .id]
                  | sort | .[0] // empty
              ) catch empty' 2>/dev/null || true)
      $jq -n --arg model "$first" '
        {
          "$schema": "https://pi.dev/schemas/settings.schema.json",
          defaultProvider: "litellm",
          enabledModels: ["litellm/*"]
        }
        + (if $model == "" then {} else { defaultModel: $model } end)
      ' > "$PI_CODING_AGENT_DIR/settings.json"
    fi

    exec ${lib.getExe piPkg} "$@"
  '';
in
{
  # the slirp gateway is the host; give it the name Lima normally
  # injects via its boot scripts (which a custom NixOS image skips)
  networking.hosts."host.lima.internal" = [ "192.168.5.2" ];

  # lima-init (nixos-lima's cloud-init replacement) writes the Lima mounts
  # into /etc/fstab but never creates missing mountpoint directories, so
  # mounts into directories that don't exist yet fail with ENOENT (e.g.
  # /var/lib/litellm). Create them and mount after lima-init has run.
  systemd.services.lima-mountpoints = {
    description = "Create missing Lima mount points and mount them";
    after = [ "lima-init.service" ];
    wants = [ "lima-init.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      pkgs.gawk
      pkgs.util-linux
    ];
    script = ''
      set -eu
      [ -f /etc/fstab ] || exit 0
      awk '/^#LIMA-START/{f=1; next} /^#LIMA-END/{f=0} f && NF >= 2 {print $2}' /etc/fstab \
        | while IFS= read -r mp; do
            [ -n "$mp" ] || continue
            mkdir -p "$mp"
            if ! mountpoint -q "$mp"; then
              echo "lima-mountpoints: mounting $mp"
              mount "$mp"
            fi
          done
    '';
  };

  # keep the image filename stable across rebuilds; the default
  # nixos-image-<label>-<arch>.qcow2 changes with every nixpkgs bump,
  # but lima.yaml points at nixos.qcow2
  image.modules.qemu-efi.image.baseName = "nixos";

  environment.systemPackages = [
    piWrapped
    pkgs.curl
    pkgs.jq
    pkgs.git
  ];
}
