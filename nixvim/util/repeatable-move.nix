# fn(forward) -> a ;/,-repeatable move; returns (next, prev) callables. No upstream pair fn, so hand-rolled.
{
  flake.nixvimModules.default.extraConfigLuaPre = ''
    function _G.MkRepeatMove(fn)
      local rm = require("nvim-treesitter-textobjects.repeatable_move")
      local move = rm.make_repeatable_move(function(opts) fn(opts.forward) end)
      return function() move({ forward = true }) end, function() move({ forward = false }) end
    end
  '';
}
