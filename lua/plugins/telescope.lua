-- Telescope: the fuzzy finder. Your main way of getting anywhere.
--
--   <leader><space>  open files in the project      (the one to remember)
--   <leader>/        search text across the project
--   <leader>fr       recently opened files
--
-- Inside a picker: <C-j>/<C-k> move, <CR> open, <C-v> open in a vertical
-- split, <C-t> open in a new tab, <C-q> send all results to the quickfix
-- list, <Tab> multi-select.

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Native C sorter: noticeably faster on large repos. Needs make + gcc,
      -- both present on this machine.
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      -- Route vim.ui.select through Telescope, so code-action menus and
      -- similar prompts get the same interface
      "nvim-telescope/telescope-ui-select.nvim",
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },

    keys = {
      -- Files
      { "<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fF", "<cmd>Telescope find_files hidden=true no_ignore=true<CR>", desc = "Find files (incl. hidden)" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },

      -- Text
      { "<leader>/", "<cmd>Telescope live_grep<CR>", desc = "Grep project" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep project" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", mode = "v", desc = "Grep selection" },
      { "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },

      -- Vim itself
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help pages" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fR", "<cmd>Telescope resume<CR>", desc = "Resume last picker" },

      -- Git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Git commits" },
      { "<leader>gB", "<cmd>Telescope git_branches<CR>", desc = "Git branches" },
      { "<leader>gS", "<cmd>Telescope git_status<CR>", desc = "Git status" },

      -- Search this config
      {
        "<leader>fn",
        function()
          require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find in Neovim config",
      },
    },

    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          prompt_prefix = vim.g.have_nerd_font and "   " or "> ",
          selection_caret = vim.g.have_nerd_font and " " or "> ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
            width = 0.9,
            height = 0.85,
          },
          file_ignore_patterns = {
            "%.git/", "node_modules/", "%.venv/", "__pycache__/",
            "%.mypy_cache/", "%.pytest_cache/", "dist/", "build/",
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<C-u>"] = false, -- clear the prompt instead of scrolling docs
              ["<Esc>"] = actions.close, -- close straight from insert mode
            },
          },
        },
        pickers = {
          find_files = { hidden = false },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      }
    end,

    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
    end,
  },
}
