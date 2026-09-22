-- Editor options. Every name here is documented: `:help 'optionname'`

-- Set this to false if icons render as boxes or question marks: it means the
-- terminal font is not a Nerd Font. Every plugin in this config reads it.
-- Install one from https://www.nerdfonts.com and set your terminal to use it.
vim.g.have_nerd_font = true

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation. 4 spaces by default; 2-space languages are overridden in
-- autocmds.lua, and any project with an .editorconfig wins over both.
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- Searching
opt.ignorecase = true
opt.smartcase = true -- ...unless the query contains a capital letter
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.wrap = false
opt.cursorline = true
opt.signcolumn = "yes" -- always reserved, so the text never shifts sideways
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true
opt.showmode = false -- lualine already shows the mode
opt.pumheight = 12 -- max entries visible in the completion popup
opt.winborder = "rounded" -- default border for every floating window

-- Splits open where you expect them to
opt.splitright = true
opt.splitbelow = true

-- Files and history
opt.undofile = true -- undo survives closing the file
opt.swapfile = false
opt.backup = false
opt.updatetime = 250 -- drives CursorHold: diagnostics, git blame, highlights
opt.timeoutlen = 400 -- how long which-key waits before showing its menu

-- Behaviour
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- yank goes to the system clipboard
opt.confirm = true -- ask to save rather than refusing to :q
opt.inccommand = "split" -- live preview while typing :%s/foo/bar/
opt.completeopt = { "menu", "menuone", "noselect" }

-- Make invisible characters visible
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Folding, provided by treesitter. Starts fully open; zc closes, za toggles.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Disable the unused language providers so :checkhealth stays quiet
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
