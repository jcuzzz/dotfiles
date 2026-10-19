-- Interface chrome: status bar, tab bar, keybind menu, indent guides.

return {
  -- ====================================================================
  -- which-key: press <leader> and wait, and a menu shows every key you
  -- can press next. The fastest way to learn your own config.
  -- ====================================================================
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      delay = 400,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code / LSP" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>t", group = "test" },
        { "<leader>u", group = "toggle / ui" },
        { "<leader>x", group = "diagnostics" },
        { "g", group = "goto" },
        { "]", group = "next" },
        { "[", group = "previous" },
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Keymaps for this buffer",
      },
    },
  },

  -- ====================================================================
  -- Status line
  -- ====================================================================
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
    opts = {
      options = {
        theme = "auto", -- follows whichever colorscheme is active
        globalstatus = true, -- one status line for the whole window, not per split
        component_separators = { left = "│", right = "│" },
        section_separators = "",
        disabled_filetypes = { statusline = { "neo-tree", "dashboard" } },
      },
      sections = {
        lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
        lualine_b = { "branch" },
        lualine_c = {
          { "diagnostics", symbols = vim.g.have_nerd_font
            and { error = " ", warn = " ", info = " ", hint = " " } or nil },
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
        },
        lualine_x = {
          -- Show when format-on-save is switched off, so you never wonder
          {
            function() return "no-fmt" end,
            cond = function() return vim.g.disable_autoformat or vim.b.disable_autoformat end,
            color = { fg = "#FFC66D" },
          },
          { "diff" },
          { "filetype" },
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "neo-tree", "lazy", "trouble", "quickfix", "toggleterm", "nvim-dap-ui" },
    },
  },

  -- ====================================================================
  -- Tab bar for open files
  -- ====================================================================
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<CR>", desc = "Pin buffer" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<CR>", desc = "Close unpinned buffers" },
      { "<leader>bl", "<cmd>BufferLineCloseRight<CR>", desc = "Close buffers to the right" },
      { "<leader>bh", "<cmd>BufferLineCloseLeft<CR>", desc = "Close buffers to the left" },
    },
    opts = {
      options = {
        -- Diagnostics in the tab bar are deliberately off: bufferline
        -- redraws the whole tabline on every DiagnosticChanged event, and
        -- the counts duplicate what lualine and the sign column show.
        diagnostics = false,
        always_show_bufferline = false,
        show_buffer_close_icons = false,
        separator_style = "thin",
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "left" },
        },
      },
    },
  },

  -- ====================================================================
  -- Indent guides
  -- ====================================================================
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│", tab_char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "help", "dashboard", "neo-tree", "Trouble", "trouble", "lazy",
          "mason", "notify", "toggleterm", "lspinfo", "checkhealth",
        },
      },
    },
  },

  -- ====================================================================
  -- Prettier vim.ui.input / notifications
  -- ====================================================================
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
