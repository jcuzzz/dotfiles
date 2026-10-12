-- Editing conveniences.

return {
  -- Typing ( gives you (), typing " gives you "", and it is smart enough
  -- not to double up when a closing character already follows.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true }, -- use the syntax tree to decide
  },

  -- Surround: operate on the thing wrapping your text.
  --   ysiw"   surround the word with quotes
  --   cs"'    change surrounding " to '
  --   ds"     delete surrounding quotes
  --   S"      in visual mode, surround the selection
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    version = "*",
    opts = {},
  },

  -- TODO / FIXME / HACK / NOTE comments get highlighted and become searchable
  --   <leader>ft   list every one in the project
  --   ]t / [t      jump between them
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = vim.g.have_nerd_font },
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Todo comments" },
      { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Todo list" },
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo" },
    },
  },

  -- Sessions: reopen a project and get your buffers and layout back.
  --   <leader>us   restore the session for this directory
  --   <leader>ul   restore the last session, wherever it was
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>us", function() require("persistence").load() end, desc = "Restore session (this dir)" },
      { "<leader>ul", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>ud", function() require("persistence").stop() end, desc = "Do not save this session" },
    },
  },

  -- Start screen: recent files and projects when you open nvim with no file
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      return {
        theme = "hyper",
        config = {
          week_header = { enable = true },
          shortcut = {
            { desc = " Files", group = "Label", action = "Telescope find_files", key = "f" },
            { desc = " Grep", group = "Label", action = "Telescope live_grep", key = "g" },
            { desc = " Session", group = "Label", action = "lua require('persistence').load()", key = "s" },
            { desc = " Config", group = "Label", action = "Telescope find_files cwd=" .. vim.fn.stdpath("config"), key = "c" },
            { desc = "󰒲 Lazy", group = "Label", action = "Lazy", key = "l" },
          },
          project = { enable = true, limit = 5 },
          mru = { limit = 8 },
          footer = {},
        },
      }
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
  },
}
