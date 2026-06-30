# Formatting (conform): plugin, changed-lines autoformat-on-save, format keymaps, and toggles.
{
  flake.nixvimModules.default = {

    # Format only the VCS-changed lines (gitsigns hunks), bottom-up so earlier line numbers stay
    # valid as edits shift them. Extra conform opts (e.g. formatters) merge into each call.
    # Returns true if the buffer has a git base (hunks processed, maybe zero); false if there's no
    # git context (nil hunks), so the caller can full-format instead.
    extraConfigLuaPre = ''
      function _G.FormatHunks(bufnr, opts)
        local hunks = require("gitsigns").get_hunks(bufnr)
        if hunks == nil then
          return false -- no repo / untracked -> let the caller decide
        end
        if vim.tbl_isempty(hunks) then
          return true -- tracked but unchanged -> don't format
        end
        -- conform picks clients by rangeFormatting when a range is set and otherwise falls
        -- back to CLI formatters, so a hunk nothing can range-format is just skipped.
        local format = require("conform").format
        for i = #hunks, 1, -1 do
          local hunk = hunks[i]
          if hunk.type ~= "delete" then
            local first = hunk.added.start
            local last = first + hunk.added.count
            -- nvim_buf_get_lines is 0-based end-exclusive; grab the last changed line for its length
            local last_line = vim.api.nvim_buf_get_lines(bufnr, last - 2, last - 1, true)[1]
            format(vim.tbl_extend("error", opts or {}, {
              bufnr = bufnr,
              async = false, -- must be sync: each pass shifts nothing while we walk upward
              range = { start = { first, 0 }, ["end"] = { last - 1, #last_line } },
            }))
          end
        end
        return true
      end
    '';

    plugins.conform-nvim = {
      enable = true;
      autoInstall.enable = true; # bake the formatter packages into the wrapper.
      settings = {
        default_format_opts.lsp_format = "prefer"; # CLI is the fallback
        # Format VCS-changed lines on save, outer language then injected blocks.
        # No git context (nil hunks: no repo or untracked) -> full format of both.
        format_on_save.__raw = ''
          function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
              return
            end
            -- lsp_format = "never" so conform runs the injected formatter instead of short-circuiting to LSP-only.
            local injected = { formatters = { "injected" }, lsp_format = "never" }
            if _G.FormatHunks(bufnr) then
              _G.FormatHunks(bufnr, injected) -- changed hunks: outer done above, now injected
            else
              require("conform").format({ bufnr = bufnr, timeout_ms = 3000 })
              require("conform").format(vim.tbl_extend("error", injected, { bufnr = bufnr, timeout_ms = 3000 }))
            end
          end
        '';
      };
    };

    keymaps = [
      {
        mode = [
          "n"
          "x"
        ];
        key = "<leader>cf";
        action.__raw = ''function() require("conform").format({ async = true }) end'';
        options.desc = "Format";
      }
      # lsp_format = "never" overrides the global "prefer" default so conform runs the injected
      # formatter instead of short-circuiting to LSP-only (which would skip it). Applies to ci too.
      {
        mode = [
          "n"
          "x"
        ];
        key = "<leader>cF";
        action.__raw = ''function() require("conform").format({ formatters = { "injected" }, lsp_format = "never", timeout_ms = 3000 }) end'';
        options.desc = "Format Injected Langs";
      }
      # Changed-lines variant of cF; normal mode only (visual-selection injected is cF). No-op when clean.
      {
        mode = "n";
        key = "<leader>ci";
        action.__raw = ''function() _G.FormatHunks(vim.api.nvim_get_current_buf(), { formatters = { "injected" }, lsp_format = "never" }) end'';
        options.desc = "Format Injected (changed)";
      }
    ];

    # Snacks toggles for disabling autoformat via :map, in Post so the Snacks global (set by snacks's own setup) already exists
    extraConfigLuaPost = ''
      Snacks.toggle({
        name = "Auto Format (Global)",
        get = function() return not vim.g.disable_autoformat end,
        set = function(state) vim.g.disable_autoformat = not state end,
      }):map("<leader>uf")
      Snacks.toggle({
        name = "Auto Format (Buffer)",
        get = function() return not (vim.g.disable_autoformat or vim.b.disable_autoformat) end,
        set = function(state) vim.b.disable_autoformat = not state end,
      }):map("<leader>uF")
    '';

  };
}
