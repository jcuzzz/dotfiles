-- Finding your way around a codebase.
--
-- trouble  a pane listing every diagnostic, reference, or quickfix entry,
--          with a preview - the equivalent of an IDE's "Problems" tab
-- aerial   a sidebar outline of the classes and functions in this file

return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      focus = true,
      warn_no_results = false,
      open_no_results = true,
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (project)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (this file)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbols" },
      { "<leader>xr", "<cmd>Trouble lsp toggle<CR>", desc = "References / definitions" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
    },
  },

  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialNavToggle" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { min_width = 28, default_direction = "right" },
      attach_mode = "global",
      show_guides = true,
      filter_kind = {
        "Class", "Constructor", "Enum", "Function", "Interface",
        "Module", "Method", "Struct",
      },
    },
    keys = {
      { "<leader>co", "<cmd>AerialToggle<CR>", desc = "Outline (symbols)" },
      { "<leader>cO", "<cmd>AerialNavToggle<CR>", desc = "Outline (navigate)" },
    },
  },
}
