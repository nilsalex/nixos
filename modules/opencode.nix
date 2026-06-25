{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.programs.opencode-profiles;
  jsonFormat = pkgs.formats.json { };

  # Deep merge that concatenates lists instead of replacing them.
  # Attrsets are merged recursively; scalars are replaced (child wins).
  mergeWithListConcat =
    base: override:
    if builtins.isList base && builtins.isList override then
      base ++ override
    else if builtins.isAttrs base && builtins.isAttrs override then
      lib.zipAttrsWith (_name: vals: builtins.foldl' mergeWithListConcat (builtins.head vals) (builtins.tail vals)) [
        base
        override
      ]
    else
      override;
in
{
  options.programs.opencode-profiles = {
    enable = lib.mkEnableOption "opencode with profile support";

    package = lib.mkPackageOption pkgs "opencode" { nullable = true; };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            extends = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Name of another profile to inherit from. Values from the
                parent are used as defaults and overridden by this profile's
                own {option}`settings`, {option}`context`, {option}`skills`,
                and {option}`tui`.

                {option}`settings` and {option}`tui` are merged deeply
                (recursiveUpdate); {option}`context`, and {option}`skills`
                fall back to the parent only when unset here.
              '';
            };

            settings = lib.mkOption {
              type = jsonFormat.type;
              default = { };
              description = ''
                Configuration written to
                {file}`$XDG_CONFIG_HOME/opencode-<name>/opencode.json`.
                See <https://opencode.ai/docs/config/> for the documentation.
              '';
            };

            context = lib.mkOption {
              type = lib.types.either lib.types.lines lib.types.path;
              default = "";
              description = ''
                Global context for OpenCode, written to
                {file}`$XDG_CONFIG_HOME/opencode-<name>/AGENTS.md`.
              '';
            };

            skills = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Path to a directory of skills, symlinked to
                {file}`$XDG_CONFIG_HOME/opencode-<name>/skills/`.
              '';
            };

            tui = lib.mkOption {
              type = jsonFormat.type;
              default = { };
              description = ''
                TUI-specific configuration written to
                {file}`$XDG_CONFIG_HOME/opencode-<name>/tui.json`.
              '';
            };
          };
        }
      );
      default = { };
      description = "Opencode profiles.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ (
      lib.mapAttrsToList (
        name: _profile:
        let
          dir = "$HOME/.config/opencode-${name}";
        in
        pkgs.writeShellScriptBin "opencode-${name}" ''
          export OPENCODE_CONFIG="${dir}/opencode.json"
          export OPENCODE_CONFIG_DIR="${dir}"
          exec ${lib.getExe cfg.package} "$@"
        ''
      ) cfg.profiles
    );

    xdg.configFile = builtins.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          name: profile:
          let
            dir = "opencode-${name}";
            parent = if profile.extends != null then cfg.profiles.${profile.extends} else null;
            base = if parent != null then parent else { settings = { }; context = ""; skills = null; tui = { }; };
            settings = mergeWithListConcat base.settings profile.settings;
            context = if profile.context != "" then profile.context else base.context;
            skills = if profile.skills != null then profile.skills else base.skills;
            tui = mergeWithListConcat base.tui profile.tui;
          in
          lib.optional (settings != { }) {
            name = "${dir}/opencode.json";
            value.source = jsonFormat.generate "opencode-${name}.json" (
              { "$schema" = "https://opencode.ai/config.json"; } // settings
            );
          }
          ++
          lib.optional (context != "") (
            if lib.isPath context then
              {
                name = "${dir}/AGENTS.md";
                value.source = context;
              }
            else
              {
                name = "${dir}/AGENTS.md";
                value.text = context;
              }
          )
          ++
          lib.optional (skills != null) {
            name = "${dir}/skills";
            value = {
              source = skills;
              recursive = true;
            };
          }
          ++
          lib.optional (tui != { }) {
            name = "${dir}/tui.json";
            value.source = jsonFormat.generate "tui-${name}.json" (
              { "$schema" = "https://opencode.ai/tui.json"; } // tui
            );
          }
        ) cfg.profiles
      )
    );
  };
}
