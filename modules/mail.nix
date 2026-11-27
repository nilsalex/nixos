{ lib, ... }:
{
  options.my.mail = {
    sopsMbsync = lib.mkEnableOption ''
      using sops-nix and the dedicated mbsync user for mail passwords
    '';

    mbsyncCredentials = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        systemd credential name to secret path mapping. Each entry becomes a
        LoadCredential for the mbsync service and is exposed to that service as
        $CREDENTIALS_DIRECTORY/<name>.
      '';
    };
  };
}
