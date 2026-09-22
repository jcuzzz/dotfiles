-- Keymaps that do not belong to any single plugin.
-- Plugin keymaps live next to their plugin in lua/plugins/, so that deleting
-- a plugin file removes its keybinds with it.
--
-- <leader> is the spacebar (set in config/lazy.lua, before plugins load).

local map = vim.keymap.set

-- Escape also clears the leftover search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Files
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qall<CR>", { desc = "Quit all" })

-- Move between splits without the <C-w> prefix
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Resize splits with the arrow keys
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Taller" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Shorter" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Narrower" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Wider" })

-- Splits
map("n", "<leader>-", "<cmd>split<CR>", { desc = "Split below" })
map("n", "<leader>|", "<cmd>vsplit<CR>", { desc = "Split right" })

-- Buffers. Shift-h / Shift-l walk the open files.
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bo", "<cmd>%bdelete|edit#|bdelete#<CR>", { desc = "Delete other buffers" })

-- Move the current line, or the selection, up and down
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep the cursor centred while jumping around
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next match" })
map("n", "N", "Nzzzv", { desc = "Previous match" })

-- Re-indenting keeps the selection, so you can press > repeatedly
map("v", "<", "<gv", { desc = "Outdent" })
map("v", ">", ">gv", { desc = "Indent" })

-- Paste over a selection without losing what you had yanked
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Diagnostics
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Terminal: Esc gets you back to normal mode instead of being swallowed
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
