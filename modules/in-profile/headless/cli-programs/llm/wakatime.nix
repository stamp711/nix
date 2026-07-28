# Self-contained WakaTime plugins (node + wakatime-cli pinned for their hooks)
{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    let
      claude-wakatime =
        let
          src = inputs.claude-code-wakatime;
          run = pkgs.writeShellScript "claude-code-wakatime-run" ''
            export PATH=${pkgs.wakatime-cli}/bin:$PATH
            unset NODE_OPTIONS
            exec ${pkgs.nodejs}/bin/node ${src}/dist/index.js "$@"
          '';
        in
        pkgs.runCommand "claude-code-wakatime" { } ''
          cp -r ${src} $out
          chmod -R +w $out
          install -m755 ${run} $out/scripts/run
        '';

      codex-wakatime =
        let
          src = "${inputs.codex-cli-wakatime}/plugins/codex-cli-wakatime"; # Codex plugin lives in a marketplace subdir
          run = pkgs.writeShellScript "codex-cli-wakatime-run" ''
            export PATH=${pkgs.wakatime-cli}/bin:$PATH
            unset NODE_OPTIONS
            exec ${pkgs.nodejs}/bin/node ${src}/bin/codex-cli-wakatime.js --background
          '';
        in
        pkgs.runCommand "codex-cli-wakatime" { } ''
          cp -r ${src} $out
          chmod -R +w $out
          install -m755 ${run} $out/scripts/run
        '';

      # No prebuilt bundle upstream, so build it.
      opencode-wakatime = pkgs.buildNpmPackage {
        pname = "opencode-wakatime";
        version = "1.3.9";
        src = inputs.opencode-wakatime;
        # It normally resolves wakatime-cli from PATH and downloads one when absent,
        # we pin the nix store one instead.
        postPatch = ''
          substituteInPlace src/dependencies.ts \
            --replace-fail 'const globalPath = whichSync(binaryName);' \
              'const globalPath = "${pkgs.wakatime-cli}/bin/wakatime-cli";'
        '';
        # hashes come from package-lock.json, so bumping the input needs no manual update
        npmDeps = pkgs.importNpmLock { npmRoot = inputs.opencode-wakatime; };
        npmConfigHook = pkgs.importNpmLock.npmConfigHook;
        npmFlags = [ "--ignore-scripts" ]; # husky
        installPhase = ''
          runHook preInstall
          install -Dm644 dist/bundle.js $out/wakatime.js
          runHook postInstall
        '';
      };
    in
    {
      programs.claude-code.plugins = [ claude-wakatime ];
      programs.codex.plugins = [ codex-wakatime ];
      # opencode 1.18.5 only loads plugins from here, not from settings.plugin or XDG.
      home.file.".opencode/plugin/wakatime.js".source = "${opencode-wakatime}/wakatime.js";
    };
}
