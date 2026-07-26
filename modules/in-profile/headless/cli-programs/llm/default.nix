# LLM coding assistants
{ inputs, lib, ... }:
let
  importSkills =
    root:
    lib.mapAttrs' (name: _: lib.nameValuePair name (root + "/${name}")) (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir root)
    );
in
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    let
      localSkills = importSkills ./skills;

      skills = localSkills;

      # Self-contained WakaTime plugins (node + wakatime-cli pinned for their hooks)
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
      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;
        plugins = [ claude-wakatime ];

        settings = {
          theme = "auto";
          tui = "fullscreen";
          effortLevel = "xhigh";
          alwaysThinkingEnabled = true;
          showThinkingSummaries = true;
          permissions =
            let
              allowRead = pattern: [
                "Read(${pattern})"
                "Bash(ls ${pattern})"
                "Bash(cat ${pattern})"
              ];
            in
            {
              allow = [
                "WebSearch"
                "WebFetch"
                "mcp__claude_ai_DeepWiki__read_wiki_structure"
                "mcp__claude_ai_DeepWiki__read_wiki_contents"
                "mcp__claude_ai_DeepWiki__ask_question"
              ]
              ++ allowRead "~/code/**"
              ++ allowRead "~/Developer/**"
              ++ allowRead "/nix/store/**"
              ++ allowRead "/tmp/**";
            };
          statusLine = {
            type = "command";
            command = "bash ${./statusline.sh}";
          };
        };
      };

      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;
        plugins = [ codex-wakatime ];
      };

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;
      };
      # opencode 1.18.5 only loads plugins from here, not from settings.plugin or XDG.
      home.file.".opencode/plugin/wakatime.js".source = "${opencode-wakatime}/wakatime.js";

      programs.pi-coding-agent.enable = true;

      programs.mcp.enable = true;
      programs.mcp.servers = { };
    };
}
