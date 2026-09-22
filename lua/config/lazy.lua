-- lazy.nvim: the plugin manager.
--
--   :Lazy            dashboard - install, update, profile, see what loaded
--   :Lazy update     update every plugin and rewrite lazy-lock.json
--   :Lazy restore    roll every plugin back to the versions in lazy-lock.json
--   :Lazy profile    startup time, per plugin
--
-- lazy-lock.json pins exact commits. Commit it to git and your setup is
-- reproducible on another machine.

-- The leader must be set before plugins load, or plugin keymaps bind to the
-- old leader.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Import every file in lua/plugins/. This is the line that makes
  -- "add a plugin" mean "add a file".
  spec = {
    { import = "plugins" },
  },

  install = { colorscheme = { "tokyonight" } },

  -- Check for plugin updates in the background, but do not interrupt with a
  -- popup. :Lazy shows what is available.
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },

  ui = { border = "rounded" },

  performance = {
    rtp = {
      -- Built-in plugins this config replaces or does not use
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin",
      },
    },
  },
})

-- :Lazy is reachable from the leader menu too
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Lazy (plugin manager)" })
