-- File tree sidebar.
--
--   <leader>e   toggle the tree
--   <leader>E   toggle it focused on the current file
--
-- Inside the tree: a add, d delete, r rename, c copy, x cut, p paste,
-- o or <CR> open, s vertical split, S horizontal split, H toggle hidden
-- files, ? full help.

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },

    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "File explorer" },
      { "<leader>E", "<cmd>Neotree reveal<CR>", desc = "File explorer (reveal file)" },
      { "<leader>ge", "<cmd>Neotree git_status<CR>", desc = "Git changes (tree)" },
    },

    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,

      default_component_configs = {
        indent = { with_expanders = true },
        git_status = {
          symbols = vim.g.have_nerd_font and {
            added = "", modified = "", deleted = "✖",
            renamed = "󰁕", untracked = "", ignored = "",
            unstaged = "󰄱", staged = "", conflict = "",
          } or {},
        },
      },

      window = {
        width = 34,
        mappings = {
          ["<space>"] = "none", -- do not shadow the leader key inside the tree
          ["l"] = "open",
          ["h"] = "close_node",
          ["Y"] = "copy_to_clipboard",
        },
      },

      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true, -- refresh when files change on disk
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = { "node_modules", "__pycache__", ".git" },
        },
      },
    },
  },
}
