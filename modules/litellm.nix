# litellm LLM gateway fronting an OpenAI-compatible upstream
# (default: https://api.trustedtokens.eu/v1).
#
# Runs two podman containers (see NixOS/nixpkgs#432925: the native
# services.litellm module cannot use the DB on NixOS because prisma has no
# NixOS engine binaries and the prisma client is not generated):
#
#   litellm-db  postgres on a private podman network, no published ports
#   litellm     berriai/litellm, published on 127.0.0.1:<port> only
#
# Routing model ("buckets"): one litellm team per bucket. Each bucket gets a
# team-scoped wildcard deployment in the generated config.yaml (registered into
# the router's team_pattern_routers at startup, carrying the bucket's upstream
# API key), so any model id a client sends is passed through to the upstream
# verbatim, authenticated with that bucket's key. Clients authenticate to
# litellm with a per-bucket virtual key.
#
# One-time setup:
#   1. Create the secrets file (root:root, 0600), default path
#      /var/lib/litellm/secrets:
#
#        LITELLM_MASTER_KEY=sk-<random>          # must start with "sk-"
#        UPSTREAM_KEY_PERSONAL=<upstream key>     # one per bucket, name = bucket
#                                                # uppercased, dashes -> underscores
#
#      The upstream keys are read from this file by both the litellm container
#      (config.yaml references them as os.environ/...) and the bootstrap script.
#   2. `sudo nixos-rebuild switch --flake .`
#   3. `sudo litellm-bootstrap` - creates teams and virtual keys, and installs
#      the virtual keys to ~/.config/litellm/<bucket>.key (owned by `user`,
#      mode 0400).
#   4. `sudo litellm-models <bucket>` - lists the upstream's model ids for
#      editing client configs.
#
# The postgres instance uses trust auth (no password); it is only reachable by
# containers on the private "litellm" podman network.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.litellm-proxy;

  bindHost = "127.0.0.1";
  proxyUrl = "http://${bindHost}:${toString cfg.port}";
  networkName = "litellm";

  user = config.users.users.${cfg.user};

  # Per-bucket team-scoped wildcard deployments. Registered into the router's
  # team_pattern_routers at config load (no premium gate there, unlike /model/new
  # which is enterprise-only): each team's keys get any model id they request
  # forwarded verbatim to the upstream with the bucket's own key.
  modelList = map (bucket: {
    model_name = "trustedtokens-${bucket}";
    litellm_params = {
      model = "openai/*";
      api_base = cfg.upstreamBaseUrl;
      api_key = "os.environ/UPSTREAM_KEY_${lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] bucket)}";
    };
    model_info = {
      team_id = bucket;
      team_public_model_name = "*";
    };
  }) cfg.buckets;

  # Authenticated pass-through to the upstream /v1/models so clients (which
  # only hold a virtual key) can fetch the live model catalog. auth=true
  # enforces virtual-key auth on the proxy side; the upstream key is injected
  # from the container env and never leaves the proxy. Note: pass-through
  # routes are not team-scoped, so every valid key can read every bucket's
  # catalog (model ids only, not secrets).
  passThroughEndpoints = map (bucket: {
    path = "/upstream/${bucket}/v1/models";
    target = "${cfg.upstreamBaseUrl}/models";
    auth = true;
    headers = {
      Authorization = "Bearer os.environ/UPSTREAM_KEY_${
        lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] bucket)
      }";
    };
  }) cfg.buckets;

  configFile = pkgs.writeText "litellm-config.yaml" (
    builtins.toJSON {
      general_settings = {
        database_url = "os.environ/DATABASE_URL";
        store_model_in_db = true;
        pass_through_endpoints = passThroughEndpoints;
      };
      litellm_settings = {
        drop_params = true;
        telemetry = false;
      };
      model_list = modelList;
    }
  );

  bucketArgs = lib.concatStringsSep " " (map lib.escapeShellArg cfg.buckets);

  # runtime tool paths baked into the scripts
  coreutils = "${pkgs.coreutils}/bin";

  litellm-bootstrap = pkgs.writeShellScriptBin "litellm-bootstrap" ''
    set -euo pipefail
    curl="${pkgs.curl}/bin/curl"
    jq="${pkgs.jq}/bin/jq"
    if [ "$(${coreutils}/id -u)" -ne 0 ]; then
      echo "litellm-bootstrap must run as root (it reads ${cfg.environmentFile})." >&2
      exit 1
    fi
    if [ ! -f ${cfg.environmentFile} ]; then
      echo "Create ${cfg.environmentFile} first - see modules/litellm.nix." >&2
      exit 1
    fi
    set -a
    . ${cfg.environmentFile}
    set +a
    : "''${LITELLM_MASTER_KEY:?LITELLM_MASTER_KEY is not set in ${cfg.environmentFile}}"
    base="${proxyUrl}"
    auth="Authorization: Bearer $LITELLM_MASTER_KEY"

    echo "Waiting for litellm at $base ..."
    until $curl -fsS "$base/health/liveliness" >/dev/null 2>&1; do
      ${coreutils}/sleep 2
    done

    ${coreutils}/mkdir -p ${cfg.stateDir}/keys
    ${coreutils}/chmod 700 ${cfg.stateDir}/keys

    for bucket in ${bucketArgs}; do
      upvar="UPSTREAM_KEY_$(printf %s "$bucket" | tr 'a-z-' 'A-Z_')"
      upkey=$(printenv "$upvar" || true)
      if [ -z "$upkey" ]; then
        echo "WARNING: $upvar not set in ${cfg.environmentFile}, skipping bucket $bucket" >&2
        continue
      fi

      # 1. team (idempotent) + grant the bucket's catalog pass-through route.
      #    auth=true pass-through routes need an explicit allowlist in team
      #    metadata (allowed_passthrough_routes); /team/update merge-patches
      #    metadata, so re-asserting it on existing teams is safe.
      meta="{\"allowed_passthrough_routes\":[\"/upstream/$bucket/v1/models\"]}"
      code=$($curl -s -o /dev/null -w '%{http_code}' "$base/team/info?team_id=$bucket" -H "$auth")
      if [ "$code" = 200 ]; then
        $curl -fsS -X POST "$base/team/update" -H "$auth" -H 'Content-Type: application/json' \
          -d "{\"team_id\":\"$bucket\",\"metadata\":$meta}" >/dev/null
        echo "team $bucket: exists (pass-through grant ensured)"
      else
        $curl -fsS -X POST "$base/team/new" -H "$auth" -H 'Content-Type: application/json' \
          -d "{\"team_id\":\"$bucket\",\"team_alias\":\"$bucket\",\"metadata\":$meta}" >/dev/null
        echo "team $bucket: created"
      fi

      # 2. wildcard deployment: comes from config.yaml (model_list), nothing
      #    to do here - /model/new is enterprise-gated in litellm

      # 3. virtual key (idempotent: kept in the state dir once generated)
      keyfile="${cfg.stateDir}/keys/$bucket"
      if [ ! -s "$keyfile" ]; then
        key=$($curl -fsS -X POST "$base/key/generate" -H "$auth" -H 'Content-Type: application/json' \
          -d "{\"team_id\":\"$bucket\",\"key_alias\":\"$bucket\"}" \
          | $jq -r '.key // .token // empty')
        if [ -z "$key" ]; then
          echo "key $bucket: generation failed" >&2
          exit 1
        fi
        umask 077
        printf %s "$key" > "$keyfile"
        echo "key $bucket: generated"
      fi

      # 4. install for the user (opencode config reads it via {file:...})
      ${coreutils}/install -D -o ${user.name} -g ${user.group} -m 400 \
        "$keyfile" "${user.home}/.config/litellm/$bucket.key"
      echo "key $bucket: installed to ~/.config/litellm/$bucket.key"
    done

    echo "Done. List upstream models with: sudo litellm-models <bucket>"
  '';

  litellm-models = pkgs.writeShellScriptBin "litellm-models" ''
    set -euo pipefail
    curl="${pkgs.curl}/bin/curl"
    jq="${pkgs.jq}/bin/jq"
    if [ "$(${coreutils}/id -u)" -ne 0 ]; then
      echo "litellm-models must run as root (it reads ${cfg.environmentFile})." >&2
      exit 1
    fi
    bucket=''${1:-}
    if [ -z "$bucket" ]; then
      echo "usage: litellm-models <bucket>" >&2
      exit 1
    fi
    [ -f ${cfg.environmentFile} ] || { echo "missing ${cfg.environmentFile}" >&2; exit 1; }
    set -a
    . ${cfg.environmentFile}
    set +a
    upvar="UPSTREAM_KEY_$(printf %s "$bucket" | tr 'a-z-' 'A-Z_')"
    upkey=$(printenv "$upvar" || true)
    [ -n "$upkey" ] || { echo "$upvar not set in ${cfg.environmentFile}" >&2; exit 1; }
    $curl -fsS -H "Authorization: Bearer $upkey" "${cfg.upstreamBaseUrl}/models" \
      | $jq -r '(.data // .) | .[] | .id'
  '';

  litellm-verify = pkgs.writeShellScriptBin "litellm-verify" ''
    set -euo pipefail
    curl="${pkgs.curl}/bin/curl"
    jq="${pkgs.jq}/bin/jq"
    bucket=''${1:-}
    model=''${2:-}
    if [ -z "$bucket" ] || [ -z "$model" ]; then
      echo "usage: litellm-verify <bucket> <model-id>   (sends a tiny request through the proxy)" >&2
      exit 1
    fi
    keyfile="$HOME/.config/litellm/$bucket.key"
    [ -s "$keyfile" ] || { echo "no key for bucket $bucket - run: sudo litellm-bootstrap" >&2; exit 1; }
    key=$(${coreutils}/cat "$keyfile")
    headers=$(${coreutils}/mktemp)
    resp=$($curl -sS -D "$headers" -X POST "${proxyUrl}/v1/chat/completions" \
      -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
      -d "$($jq -nc --arg m "$model" '{model: $m, messages: [{role: "user", content: "Reply with the single word: OK"}], max_tokens: 16}')")
    echo "--- serving deployment:"
    grep -i '^x-litellm-model-id' "$headers" || echo "(no x-litellm-model-id header)"
    echo "--- response:"
    printf '%s\n' "$resp" | $jq . 2>/dev/null || printf '%s\n' "$resp"
    ${coreutils}/rm -f "$headers"
  '';
in
{
  options.services.litellm-proxy = {
    enable = lib.mkEnableOption "litellm gateway (podman containers, teams-based routing)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "Port litellm listens on (bound to 127.0.0.1 only).";
    };

    buckets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "personal" ];
      description = ''
        Project buckets: each gets a litellm team, a wildcard deployment
        forwarding every model id verbatim to the upstream with the bucket's
        own API key, and a virtual key installed to
        {file}`~/.config/litellm/<bucket>.key`. The upstream key for a
        bucket is read from {option}`environmentFile` as
        `UPSTREAM_KEY_<BUCKET>` (uppercased, dashes replaced by
        underscores).
      '';
    };

    upstreamBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://api.trustedtokens.eu/v1";
      description = "OpenAI-compatible base URL of the upstream.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/litellm/secrets";
      description = ''
        Environment file (root:root, 0600, create by hand) with
        `LITELLM_MASTER_KEY=sk-...` and one
        `UPSTREAM_KEY_<BUCKET>=...` per bucket. Passed to the litellm
        container.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/litellm";
      description = "Directory for the postgres data dir and generated virtual keys.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "nils";
      description = "User the virtual keys are installed for.";
    };

    litellmImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/berriai/litellm:main-stable";
      description = "litellm container image (Docker Hub no longer serves berriai/litellm).";
    };

    postgresImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/library/postgres:17";
      description = "postgres container image.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.buckets != [ ];
        message = "services.litellm-proxy.buckets must not be empty";
      }
      {
        assertion = cfg.buckets == lib.unique cfg.buckets;
        message = "services.litellm-proxy.buckets contains duplicates";
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${toString cfg.stateDir} 0755 root root -"
      # rootful podman does not auto-create bind-mount sources
      "d ${toString cfg.stateDir}/db 0755 root root -"
      "d ${toString cfg.stateDir}/keys 0700 root root -"
    ];

    systemd.services.litellm-network = {
      description = "Podman network for the litellm stack";
      wantedBy = [ "multi-user.target" ];
      before = [
        "podman-litellm.service"
        "podman-litellm-db.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "litellm-network-create" ''
          ${config.virtualisation.podman.package}/bin/podman network exists ${networkName} \
            || ${config.virtualisation.podman.package}/bin/podman network create ${networkName}
        '';
      };
    };

    systemd.services.podman-litellm-db.wants = [ "litellm-network.service" ];
    systemd.services.podman-litellm.wants = [ "litellm-network.service" ];

    virtualisation.oci-containers.containers = {
      litellm-db = {
        image = cfg.postgresImage;
        environment = {
          POSTGRES_USER = "litellm";
          POSTGRES_DB = "litellm";
          # trust auth: the DB is only reachable on the private podman network
          POSTGRES_HOST_AUTH_METHOD = "trust";
        };
        volumes = [ "${toString cfg.stateDir}/db:/var/lib/postgresql/data" ];
        networks = [ networkName ];
      };

      litellm = {
        image = cfg.litellmImage;
        cmd = [
          "--config"
          "/etc/litellm/config.yaml"
          "--host"
          "0.0.0.0"
          "--port"
          "4000"
        ];
        environment = {
          DATABASE_URL = "postgresql://litellm@litellm-db:5432/litellm";
          STORE_MODEL_IN_DB = "True";
        };
        environmentFiles = [ (toString cfg.environmentFile) ];
        volumes = [ "${configFile}:/etc/litellm/config.yaml:ro" ];
        ports = [ "${bindHost}:${toString cfg.port}:4000" ];
        dependsOn = [ "litellm-db" ];
        networks = [ networkName ];
      };
    };

    environment.systemPackages = [
      litellm-bootstrap
      litellm-models
      litellm-verify
    ];
  };
}
