{
  flake.nixvimModules.default =
    # Editor settings & behavior.
    {
      # nixvim's vim-default leader is \, so set space explicitly to match intent.
      globals = {
        mapleader = " ";
        maplocalleader = "\\"; # frees , for the ;/, repeat.
      };

      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        signcolumn = "yes";
        # merged sign/number/fold/git gutter, rendered by snacks
        statuscolumn = "%!v:lua.require'snacks.statuscolumn'.get()";
        scrolloff = 8;
        cursorline = true;
        splitright = true;
        splitbelow = true;

        autowrite = true;
        confirm = true;
        undofile = true;
        undolevels = 10000;
        updatetime = 200;
        timeoutlen = 300;

        ignorecase = true;
        smartcase = true;
        inccommand = "nosplit";

        completeopt = "menu,menuone,noselect";
        conceallevel = 2;
        formatexpr = "v:lua.require'conform'.formatexpr()"; # gq runs conform
        formatoptions = "jcroqlnt";

        grepprg = "rg --vimgrep";
        grepformat = "%f:%l:%c:%m";

        list = true;
        linebreak = true;
        wrap = false;
        smoothscroll = true;
        sidescrolloff = 8;
        virtualedit = "block";
        smartindent = true;
        shiftround = true;

        laststatus = 3;
        showmode = false;
        ruler = false;
        pumblend = 10;
        pumheight = 10;
        winminwidth = 5;
        splitkeep = "screen";

        mouse = "a";
        termguicolors = true;
        wildmode = "longest:full,full";
        jumpoptions = "view";
        spelllang = [ "en" ];

        # empty over SSH so OSC52 yank works; system clipboard otherwise.
        clipboard.__raw = ''vim.env.SSH_CONNECTION and "" or "unnamedplus"'';

        sessionoptions = [
          "buffers"
          "curdir"
          "tabpages"
          "winsize"
          "help"
          "globals"
          "skiprtp"
          "folds"
        ];

        fillchars = {
          diff = "╱";
          eob = " ";
        };
      };

      # W: no "written" msg; I: no intro; c/C: no ins-completion scan messages.
      extraConfigLua = ''
        vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
      '';
    };
}
