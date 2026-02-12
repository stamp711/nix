{
  description = "1Password service account token for opnix";

  module =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.secrets.opnix-token;
      secretsDir = "${config.xdg.configHome}/secrets";
    in
    {
      imports = [ inputs.opnix.homeManagerModules.default ];

      options.secrets.opnix-token = {
        reference = lib.mkOption {
          type = lib.types.str;
          description = "1Password reference for the opnix service account token.";
        };
      };

      config = {
        programs.onepassword-secrets.enable = true;
        programs.onepassword-secrets.tokenFile = "${secretsDir}/opnix-token";

        programs.onepassword-secrets.secrets.opnixToken = {
          inherit (cfg) reference;
          path = "${secretsDir}/opnix-token";
        };
      };
    };
}
