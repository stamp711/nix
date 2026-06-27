# Structural swap: Alt-h/l swaps the node (visual: the selection; normal: at the cursor) with its same-type sibling.
{
  flake.nixvimModules.default = {
    extraConfigLua = ''
      -- swap a tree node with its previous/next same-type sibling
      local function swap_selection(fwd)
        local mode = vim.fn.mode()
        local visual = mode == "v" or mode == "V" or mode == "\22"
        local node
        if visual then
          -- largest node inside the selection
          local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
          if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then s, e = e, s end
          local sr, sc, er, ec = s[2] - 1, s[3] - 1, e[2] - 1, e[3]
          if mode == "V" then sc, ec = 0, math.huge end
          node = vim.treesitter.get_node({ pos = { sr, sc } })
          while node do
            local p = node:parent()
            if not p then break end
            local psr, psc, per, pec = p:range()
            if psr < sr or (psr == sr and psc < sc) or per > er or (per == er and pec > ec) then break end
            node = p
          end
        else
          -- node at the cursor, ascended until it has a same-type sibling
          node = vim.treesitter.get_node()
          while node do
            local t = node:type()
            local n, p = node:next_named_sibling(), node:prev_named_sibling()
            if (n and n:type() == t) or (p and p:type() == t) then break end
            node = node:parent()
          end
        end
        if not node then return end

        local t = node:type()
        local sib = fwd and node:next_named_sibling() or node:prev_named_sibling()
        while sib and sib:type() ~= t do
          sib = fwd and sib:next_named_sibling() or sib:prev_named_sibling()
        end
        if not sib then return end

        local a, b = { node:range() }, { sib:range() }
        local lo, hi = a, b
        if a[1] > b[1] or (a[1] == b[1] and a[2] > b[2]) then lo, hi = b, a end
        local lt = vim.api.nvim_buf_get_text(0, lo[1], lo[2], lo[3], lo[4], {})
        local ht = vim.api.nvim_buf_get_text(0, hi[1], hi[2], hi[3], hi[4], {})
        vim.api.nvim_buf_set_text(0, hi[1], hi[2], hi[3], hi[4], lt)
        vim.api.nvim_buf_set_text(0, lo[1], lo[2], lo[3], lo[4], ht)

        -- land on the moved node (re-select to bubble further)
        local row = fwd and (b[1] + (b[3] - b[1]) - (a[3] - a[1])) or b[1]
        local col = b[2]
        if fwd and a[3] == b[1] then col = col + (#ht[#ht] - #lt[#lt]) end
        if visual then vim.cmd("normal! \27") end
        vim.api.nvim_win_set_cursor(0, { row + 1, col })
      end
      _G.SwapSelection = swap_selection
    '';

    keymaps = [
      # Swap forward/backward (parallels <A-j>/<A-k> move-line).
      {
        mode = [
          "n"
          "x"
        ];
        key = "<A-l>";
        action.__raw = "function() _G.SwapSelection(true) end";
        options.desc = "Swap node forward";
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<A-h>";
        action.__raw = "function() _G.SwapSelection(false) end";
        options.desc = "Swap node backward";
      }
    ];
  };
}
