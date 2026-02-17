# Extended agenix-template with envFiles support.
# Based on https://github.com/jhillyerd/agenix-template
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.age-template;

  fileConfig =
    with types;
    submodule (
      { config, ... }:
      {
        options = {
          name = mkOption {
            type = str;
            default = config._module.args.name;
            description = "Name of the template";
          };

          vars = mkOption {
            type = attrsOf path;
            description = ''
              Mapping of variable names to files.
              Names must start with a lowercase letter and be valid bash names.
            '';
            default = { };
          };

          envFiles = mkOption {
            type = listOf path;
            description = ''
              List of env-format secret files (KEY=VALUE per line) to source.
              All variables defined in these files become available for substitution.
            '';
            default = [ ];
          };

          content = mkOption {
            type = str;
            description = ''
              Content of template.
              `$name` will be replaced with the content of file in `vars.name`
              or a variable sourced from `envFiles`.
            '';
            default = "";
          };

          path = mkOption {
            type = str;
            description = "Path (with filename) to store generated output";
            default = "${cfg.directory}/${config.name}";
          };

          owner = mkOption {
            type = str;
            default = "0";
          };

          group = mkOption {
            type = str;
            default = "0";
          };

          mode = mkOption {
            type = str;
            default = "0400";
          };
        };
      }
    );
in
{
  options.age-template = {
    directory = mkOption {
      type = types.path;
      default = "/run/agenix-template";
    };

    files = mkOption {
      type = types.attrsOf fileConfig;
      default = { };
    };
  };

  config =
    let
      inherit (lib) escapeShellArg mapAttrsToList;

      mkScript =
        name: entry:
        let
          templateName = "agenix-template-" + name;
          content = if hasSuffix "\n" entry.content then entry.content else entry.content + "\n";

          eDir = escapeShellArg (dirOf entry.path);
          eOutput = escapeShellArg entry.path;
          eInput = escapeShellArg (pkgs.writeText "${name}.in" content);

          # For vars: only substitute configured variable names.
          # For envFiles: we don't know var names at build time, so we
          # let envsubst substitute all exported vars.
          hasEnvFiles = entry.envFiles != [ ];
          allowedVars =
            if hasEnvFiles then
              ""
            else
              escapeShellArg (builtins.concatStringsSep " " (map (s: "$" + s) (attrNames entry.vars)));

          setEnvScript = builtins.concatStringsSep "\n" (
            mapAttrsToList (var: source: ''export ${var}="$(< ${escapeShellArg source})"'') entry.vars
          );

          sourceEnvScript = builtins.concatStringsSep "\n" (
            map (f: ''
              set -a
              . ${escapeShellArg f}
              set +a
            '') entry.envFiles
          );

          activationScript = pkgs.writeShellScript templateName ''
            set -eo pipefail

            mkdir -p ${eDir}
            chmod 701 ${eDir}

            ${sourceEnvScript}
            ${setEnvScript}
            ${pkgs.gettext}/bin/envsubst \
              ${allowedVars} \
              < ${eInput} > ${eOutput}

            chmod ${escapeShellArg entry.mode} ${eOutput}
            chown ${escapeShellArg (entry.owner + ":" + entry.group)} ${eOutput}
          '';
        in
        {
          name = templateName;
          value = stringAfter [ "etc" "agenix" ] "${activationScript}";
        };
    in
    mkIf (cfg.files != { }) {
      system.activationScripts = attrsets.mapAttrs' mkScript cfg.files;
    };
}
