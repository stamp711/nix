# Statusline (lualine), ported from LazyVim. `sub:` marks where it diverges.
{
  flake.nixvimModules.default = { lib, ... }: {
    extraConfigLuaPre = ''
      do
        local M = {}

        -- sub: LazyVim.is_win
        local function is_win() return vim.uv.os_uname().sysname:find("Windows") ~= nil end

        function M.format(component, text, hl_group)
          text = text:gsub("%%", "%%%%")
          if not hl_group or hl_group == "" then return text end
          ---@type table<string, string>
          component.hl_cache = component.hl_cache or {}
          local lualine_hl_group = component.hl_cache[hl_group]
          if not lualine_hl_group then
            local utils = require("lualine.utils.utils")
            ---@type string[]
            local gui = vim.tbl_filter(function(x) return x end, {
              utils.extract_highlight_colors(hl_group, "bold") and "bold",
              utils.extract_highlight_colors(hl_group, "italic") and "italic",
            })

            lualine_hl_group = component:create_hl({
              fg = utils.extract_highlight_colors(hl_group, "fg"),
              gui = #gui > 0 and table.concat(gui, ",") or nil,
            }, "LV_" .. hl_group) --[[@as string]]
            component.hl_cache[hl_group] = lualine_hl_group
          end
          return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
        end

        -- used by the commented copilot component below
        function M.status(icon, status)
          local colors = {
            ok = "Special",
            error = "DiagnosticError",
            pending = "DiagnosticWarn",
          }
          return {
            function() return icon end,
            cond = function() return status() ~= nil end,
            color = function() return { fg = Snacks.util.color(colors[status()] or colors.ok) } end,
          }
        end

        ---@param opts? {relative: "cwd"|"root", modified_hl: string?, directory_hl: string?, filename_hl: string?, modified_sign: string?, readonly_icon: string?, length: number?}
        function M.pretty_path(opts)
          opts = vim.tbl_extend("force", {
            relative = "cwd",
            modified_hl = "MatchParen",
            directory_hl = "",
            filename_hl = "Bold",
            modified_sign = "",
            readonly_icon = " \u{f033e} ", -- sub: glyph as escape (was " <lock> ")
            length = 3,
          }, opts or {})

          return function(self)
            local path = vim.fn.expand("%:p") --[[@as string]]

            if path == "" then return "" end

            path = vim.fs.normalize(path) -- sub: LazyVim.norm
            local root = Root({ normalize = true }) -- sub: LazyVim.root.get
            local cwd = Root.cwd() -- sub: LazyVim.root.cwd

            -- original path is preserved to provide user with expected result of pretty_path, not a normalized one,
            -- which might be confusing
            local norm_path = path

            if is_win() then -- sub: LazyVim.is_win
              -- in case any of the provided paths involved mixed case, an additional normalization step for windows
              norm_path = norm_path:lower()
              root = root:lower()
              cwd = cwd:lower()
            end

            if opts.relative == "cwd" and norm_path:find(cwd, 1, true) == 1 then
              path = path:sub(#cwd + 2)
            elseif norm_path:find(root, 1, true) == 1 then
              path = path:sub(#root + 2)
            end

            local sep = package.config:sub(1, 1)
            local parts = vim.split(path, "[\\/]")

            if opts.length == 0 then
              parts = parts
            elseif #parts > opts.length then
              parts = { parts[1], "\u{2026}", unpack(parts, #parts - opts.length + 2, #parts) } -- sub: glyph as escape (was ellipsis)
            end

            if opts.modified_hl and vim.bo.modified then
              parts[#parts] = parts[#parts] .. opts.modified_sign
              parts[#parts] = M.format(self, parts[#parts], opts.modified_hl)
            else
              parts[#parts] = M.format(self, parts[#parts], opts.filename_hl)
            end

            local dir = ""
            if #parts > 1 then
              dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
              dir = M.format(self, dir .. sep, opts.directory_hl)
            end

            local readonly = ""
            if vim.bo.readonly then readonly = M.format(self, opts.readonly_icon, opts.modified_hl) end
            return dir .. parts[#parts] .. readonly
          end
        end

        ---@param opts? {cwd:false, subdirectory: true, parent: true, other: true, icon?:string}
        function M.root_dir(opts)
          opts = vim.tbl_extend("force", {
            cwd = false,
            subdirectory = true,
            parent = true,
            other = true,
            icon = "\u{f126d} ", -- sub: glyph as escape (was "<folder> ")
            color = function() return { fg = Snacks.util.color("Special") } end,
          }, opts or {})

          local function get()
            local cwd = Root.cwd() -- sub: LazyVim.root.cwd
            local root = Root({ normalize = true }) -- sub: LazyVim.root.get
            local name = vim.fs.basename(root)

            if root == cwd then
              -- root is cwd
              return opts.cwd and name
            elseif root:find(cwd, 1, true) == 1 then
              -- root is subdirectory of cwd
              return opts.subdirectory and name
            elseif cwd:find(root, 1, true) == 1 then
              -- root is parent directory of cwd
              return opts.parent and name
            else
              -- root and cwd are not related
              return opts.other and name
            end
          end

          return {
            function() return (opts.icon and opts.icon .. " ") .. get() end,
            cond = function() return type(get()) == "string" end,
            color = opts.color,
          }
        end

        _G.LualineUtil = M -- sub: LazyVim.lualine
      end
    '';

    globals.trouble_lualine = true; # global toggle for the breadcrumb (per-buffer: vim.b.trouble_lualine)

    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "auto";
          globalstatus = true; # sub: LazyVim derives this from `vim.o.laststatus == 3`
          disabled_filetypes.statusline = [
            "dashboard"
            "snacks_dashboard"
            "alpha"
            "ministarter"
          ];
        };
        sections = {
          lualine_a = [ "mode" ]; # vim mode
          lualine_b = [ "branch" ]; # git branch

          lualine_c = [
            # project root dir name (shown when it differs from cwd)
            { __raw = "_G.LualineUtil.root_dir()"; }
            # LSP diagnostic counts
            {
              # sub: icons.diagnostics.* as \u escapes (Error/Warn/Info/Hint)
              __raw = ''
                {
                  "diagnostics",
                  symbols = {
                    error = "\u{f057} ",
                    warn = "\u{f071} ",
                    info = "\u{f05a} ",
                    hint = "\u{f0eb} ",
                  },
                }
              '';
            }
            # filetype icon
            { __raw = ''{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } }''; }
            # file path (relative to root)
            { __raw = "{ _G.LualineUtil.pretty_path() }"; }
            {
              # trouble symbol breadcrumbs (Class > method); vim.b.trouble_lualine = false opts out
              __raw = ''
                (function()
                  local symbols = require("trouble").statusline({
                    mode = "symbols",
                    groups = {},
                    title = false,
                    filter = { range = true },
                    format = "{kind_icon}{symbol.name:Normal}",
                    -- symbols mode omits the insert events -> add the *I variants so the breadcrumb tracks in insert mode
                    events = {
                      "BufEnter",
                      { event = "TextChanged", main = true },
                      { event = "TextChangedI", main = true },
                      { event = "CursorMoved", main = true },
                      { event = "CursorMovedI", main = true },
                      { event = "LspAttach", main = true },
                    },
                  })
                  local hl = require("trouble.config.highlights")
                  local mode_suffix = require("lualine.highlight").get_mode_suffix
                  return {
                    -- Repaint the breadcrumb bg onto lualine_c for the *current* mode so it blends with the bar.
                    -- fix_statusline recolors the %#hl# spans (keeps fg); the gsub does trouble's %* resets, which
                    -- otherwise fall back to StatusLine. _fixed is trouble's group cache -> clear so bg re-derives per mode.
                    function()
                      hl._fixed = {}
                      local sec = "lualine_c" .. mode_suffix()
                      return (hl.fix_statusline(symbols.get(), sec):gsub("%%%*", "%%#" .. sec .. "#"))
                    end,
                    cond = function() return vim.g.trouble_lualine and vim.b.trouble_lualine ~= false and symbols.has() end,
                  }
                end)()
              '';
            }
          ];

          # mkOrder chunks so plugins can splice in
          lualine_x = lib.mkMerge [

            # Snacks profiler status (while profiling)
            (lib.mkOrder 10 [ { __raw = "Snacks.profiler.status()"; } ])

            # order 20: sidekick (sidekick.nix)

            # pending command/operator (noice)
            (lib.mkOrder 30 [
              {
                __raw = ''
                  -- stylua: ignore
                  {
                    function() return require("noice").api.status.command.get() end,
                    cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
                    color = function() return { fg = Snacks.util.color("Statement") } end,
                  }
                '';
              }
            ])

            # macro recording (and visual-selection/search info) (noice)
            (lib.mkOrder 40 [
              {
                __raw = ''
                  -- stylua: ignore
                  {
                    function() return require("noice").api.status.mode.get() end,
                    cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
                    color = function() return { fg = Snacks.util.color("Constant") } end,
                  }
                '';
              }
            ])

            # git diff counts
            (lib.mkOrder 50 [
              {
                # sub: icons.git.* as \u escapes (added/modified/removed)
                __raw = ''
                  {
                    "diff",
                    symbols = { added = "\u{f0fe} ", modified = "\u{f14b} ", removed = "\u{f146} " },
                    source = function()
                      local gs = vim.b.gitsigns_status_dict
                      if gs then return { added = gs.added, modified = gs.changed, removed = gs.removed } end
                    end,
                  }
                '';
              }
            ])

            # copilot LSP status (needs zbirenbaum/copilot.lua's require("copilot.status")):
            # (lib.mkOrder 20 [ {
            #   __raw = ''
            #     _G.LualineUtil.status("\u{f4b8}", function()
            #       local clients = package.loaded["copilot"] and vim.lsp.get_clients({ name = "copilot", bufnr = 0 }) or {}
            #       if #clients > 0 then
            #         local status = require("copilot.status").data.status
            #         return (status == "InProgress" and "pending") or (status == "Warning" and "error") or "ok"
            #       end
            #     end)
            #   '';
            # } ])

            # dap status (needs nvim-dap):
            # (lib.mkOrder 50 [ { __raw = ''{ function() return "\u{f46f}  " .. require("dap").status() end, cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end, color = function() return { fg = Snacks.util.color("Debug") } end }''; } ])

            # lazy.nvim updates (nixvim has no lazy.nvim):
            # (lib.mkOrder 50 [ { __raw = ''{ require("lazy.status").updates, cond = require("lazy.status").has_updates, color = function() return { fg = Snacks.util.color("Special") } end }''; } ])
          ];

          lualine_y = [
            # progress through file
            { __raw = ''{ "progress", separator = " ", padding = { left = 1, right = 0 } }''; }
            # cursor line:col
            { __raw = ''{ "location", padding = { left = 0, right = 1 } }''; }
          ];

          lualine_z = [
            # current time
            # sub: clock glyph as escape (was "<clock> ")
            { __raw = ''function() return "\u{f43a} " .. os.date("%R") end''; }
          ];
        };

        extensions = [
          "quickfix"
          "trouble"
        ];
      };
    };
  };
}
