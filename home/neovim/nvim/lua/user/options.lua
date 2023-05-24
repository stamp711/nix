vim.g.mapleader = " "

local opt = vim.opt

opt.termguicolors = true

opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.smartindent = true

opt.wrap = false -- Disable line wrap

opt.list = true -- show some invisible characters

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time

opt.scrolloff = 8
opt.sidescrolloff = 8

opt.clipboard = "unnamedplus" -- sync with system clipboard
opt.completeopt = "menu,menuone,noselect,preview"
opt.confirm = true
opt.cursorline = true

opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

opt.ignorecase = true
opt.smartcase = true

opt.laststatus = 3

opt.mouse = "a"

opt.pumblend = 10
opt.pumheight = 10

-- opt.shortmess:append({ W = true, I = true, c = true })

opt.splitbelow = true
opt.splitright = true

opt.updatetime = 200 -- Save swap file and trigger CursorHold

if vim.fn.has("nvim-0.9.0") == 1 then
	opt.splitkeep = "screen"
	-- opt.shortmess:append({ C = true })
end