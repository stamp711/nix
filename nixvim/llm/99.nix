{ inputs, ... }: {
  flake.nixvimModules.default = { pkgs, ... }: {

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "99";
        version = inputs.nvim-99.shortRev or "unstable";
        src = inputs.nvim-99;
        # unused upstream WIP module; its require of a missing file only trips the build-time check
        nvimSkipModule = [ "99.editor.lsp" ];
      })
    ];

    extraConfigLua = ''
      require("99").setup({
        provider = require("99").Providers.ClaudeCodeProvider,
        -- 99 always passes --model, so pin it; it can't defer to claude-code's own default
        model = "opus",
        -- native avoids pulling blink.compat just for the prompt's #/@ completion
        completion = { source = "native" },
        md_files = { "CLAUDE.md", "AGENTS.md", "AGENT.md" },
      })

      require("which-key").add({
        { "<leader>a9", group = "99", mode = { "n", "x" } },
        { "<leader>a9w", group = "worker", mode = { "n" } },
      })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>a9s";
        action.__raw = ''function() require("99").search() end'';
        options.desc = "Search";
      }
      {
        mode = "n";
        key = "<leader>a9v";
        action.__raw = ''function() require("99").vibe() end'';
        options.desc = "Vibe";
      }
      {
        mode = "n";
        key = "<leader>a9t";
        action.__raw = ''function() require("99").tutorial() end'';
        options.desc = "Tutorial";
      }
      {
        mode = "n";
        key = "<leader>a9o";
        action.__raw = ''function() require("99").open() end'';
        options.desc = "Open Last Result";
      }
      # visual mode: operates on the current selection, not a stale one
      {
        mode = "x";
        key = "<leader>a9e";
        action.__raw = ''function() require("99").visual() end'';
        options.desc = "Edit Selection";
      }
      {
        mode = "n";
        key = "<leader>a9l";
        action.__raw = ''function() require("99").view_logs() end'';
        options.desc = "View Logs";
      }
      {
        mode = "n";
        key = "<leader>a9i";
        action.__raw = ''function() require("99").info() end'';
        options.desc = "Info";
      }
      {
        mode = "n";
        key = "<leader>a9c";
        action.__raw = ''function() require("99").clear_previous_requests() end'';
        options.desc = "Clear History";
      }
      # set_model takes a string; pick from the active provider's own model list
      {
        mode = "n";
        key = "<leader>a9m";
        action.__raw = ''
          function()
            local _99 = require("99")
            _99.get_provider().fetch_models(function(models)
              vim.schedule(function()
                vim.ui.select(models, { prompt = "99 model" }, function(choice)
                  if choice then _99.set_model(choice) end
                end)
              end)
            end)
          end
        '';
        options.desc = "Set Model";
      }
      # set_provider takes a provider object; pick from 99's own Providers table
      {
        mode = "n";
        key = "<leader>a9p";
        action.__raw = ''
          function()
            local _99 = require("99")
            local names = {}
            for name in pairs(_99.Providers) do
              if name ~= "BaseProvider" then names[#names + 1] = name end
            end
            table.sort(names)
            vim.ui.select(names, { prompt = "99 provider" }, function(choice)
              if choice then _99.set_provider(_99.Providers[choice]) end
            end)
          end
        '';
        options.desc = "Set Provider";
      }
      {
        mode = "n";
        key = "<leader>a9ws";
        action.__raw = ''function() require("99").Extensions.Worker.set_work() end'';
        options.desc = "Set Work Item";
      }
      {
        mode = "n";
        key = "<leader>a9wf";
        action.__raw = ''function() require("99").Extensions.Worker.search() end'';
        options.desc = "What's Left";
      }
      {
        mode = "n";
        key = "<leader>a9wv";
        action.__raw = ''function() require("99").Extensions.Worker.vibe() end'';
        options.desc = "Work On It";
      }
      {
        mode = "n";
        key = "<leader>a9x";
        action.__raw = ''function() require("99").stop_all_requests() end'';
        options.desc = "Stop";
      }
    ];

  };
}
