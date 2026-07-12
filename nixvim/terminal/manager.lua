local M = {
  items = {}, -- open terminals in tab order (creation order, left to right)
  selected = nil, -- the selected tab: shown now, or restored on next toggle (not the focused window)
  next_id = 1, -- id for the next tab; part of Snacks' (cwd, count) key so each tab stays distinct
}

-- `manager_win` (winbar + terminal-mode keys, scoped to manager terminals) is
-- injected by the nix wrapper in default.nix

-- position of `term` in the tab list, or nil if it's gone
local function index_of(term)
  for i, t in ipairs(M.items) do
    if t == term then
      return i
    end
  end
end

-- one visible pane: hide every terminal except `keep`
local function hide_others(keep)
  for _, t in ipairs(M.items) do
    if t ~= keep and t:win_valid() then
      t:hide()
    end
  end
end

-- select `term`, hide the others, and focus its window
local function show(term)
  hide_others(term)
  M.selected = term
  term:show():focus()
  vim.cmd("redrawstatus")
end

-- create a new terminal tab and switch to it
function M.new()
  local id = M.next_id
  M.next_id = M.next_id + 1
  -- on_close fires at the start of Snacks' win:close, before nvim_win_close tears
  -- the window down and moves focus, so here we can still see if the user was in it
  local was_focused = false
  local term = Snacks.terminal.open(nil, {
    cwd = Root(),
    count = id,
    win = vim.tbl_extend("force", manager_win, {
      on_close = function(self)
        was_focused = vim.api.nvim_get_current_buf() == self.buf
      end,
    }),
  })
  M.items[#M.items + 1] = term
  -- shell exit wipes the buffer: drop this tab; if it was selected, hand the pane
  -- to the left neighbour, but re-focus it only if the user was in the terminal
  term:on("BufWipeout", function()
    local i = index_of(term)
    local was_selected = M.selected == term
    if i then
      table.remove(M.items, i)
    end
    if was_selected then
      -- go to the tab left of the closed one (or the first, if it was leftmost)
      M.selected = M.items[math.max(1, (i or 1) - 1)]
    end
    vim.schedule(function()
      if was_focused and M.selected then
        show(M.selected)
      end
      vim.cmd("redrawstatus")
    end)
  end, { buf = true })

  show(term)
  return term
end

-- show the selected tab, or hide the pane if you're already focused in it
function M.toggle()
  if not M.selected then
    return M.new()
  end
  if M.selected:win_valid() and vim.api.nvim_get_current_buf() == M.selected.buf then
    M.selected:hide()
    vim.cmd("redrawstatus")
  else
    show(M.selected)
  end
end

-- switch to the tab `delta` positions away, wrapping around
function M.cycle(delta)
  if #M.items == 0 then
    return M.new()
  end
  local cur = index_of(M.selected) or 1
  show(M.items[((cur - 1 + delta) % #M.items) + 1])
end

-- one tab's label: the running program name, %-escaped for the statusline
local function title(term)
  local name = vim.fn.fnamemodify(vim.b[term.buf].term_title or "terminal", ":t")
  return (name ~= "" and name or "terminal"):gsub("%%", "%%%%")
end

-- inactive-tab bg = the editor Normal: distinct from the terminal's NormalFloat
-- content, and (being a custom group) not remapped by the terminal's winhighlight
-- the way %#Normal# would be. Re-derive on theme change.
local function sync_tab_hl()
  vim.api.nvim_set_hl(0, "TermTabInactive", { bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg })
end
sync_tab_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = sync_tab_hl })

-- render the winbar: the tab strip, selected tab highlighted
function M.winbar()
  local parts = {}
  for i, term in ipairs(M.items) do
    -- selected tab = terminal content bg (NormalFloat) so it connects to the pane
    -- below; inactive tabs = editor bg (TermTabInactive) so they read as separate
    local hl = term == M.selected and "NormalFloat" or "TermTabInactive"
    parts[#parts + 1] = ("%%#%s# %d:%s "):format(hl, i, title(term))
  end
  return table.concat(parts) .. "%#TermTabInactive#%="
end

_G.Terminals = M
