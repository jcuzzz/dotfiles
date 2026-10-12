-- Colour scheme.
--
-- tokyonight is used because it ships explicit themes for every plugin in
-- this config (tree, statusline, tabs, git signs, diagnostics, dap), so
-- nothing looks out of place. Two things are forced on top of it:
--
--   1. a near-black background, set in on_colors below
--   2. no italics anywhere, enforced by strip_italics() - themes and plugins
--      both like to sneak italics in, so this runs after every colorscheme
--      change rather than trusting each one's settings
--
-- To use a different theme: change the `colorscheme` call at the bottom.
-- strip_italics keeps working regardless of which theme you pick.

-- Background. "#000000" is pure black; the default below is a hair off it so
-- that floating windows and the sidebar still read as separate surfaces.
local BG = "#0A0A0C"
local BG_DARK = "#050506" -- sidebars, tab bar, inactive surfaces
local BG_FLOAT = "#0F1013" -- popups, completion menu, hover docs
local CURSORLINE = "#17191F"

local function strip_italics()
  for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
    if def.italic and not def.link then
      def.italic = false
      pcall(vim.api.nvim_set_hl, 0, name, def)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("user_no_italics", { clear = true }),
  callback = vim.schedule_wrap(strip_italics),
})

return {
  {
    "folke/tokyonight.nvim",
    lazy = false, -- the colorscheme must load before anything draws
    priority = 1000, -- ...and before every other plugin
    opts = {
      style = "night", -- the darkest of tokyonight's variants
      terminal_colors = true,

      styles = {
        comments = { italic = false },
        keywords = { italic = false, bold = true },
        functions = {},
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },

      -- Override the palette itself, so every group the theme defines picks
      -- these up rather than only the handful listed in on_highlights.
      on_colors = function(c)
        c.bg = BG
        c.bg_dark = BG_DARK
        c.bg_dark1 = BG_DARK
        c.bg_float = BG_FLOAT
        c.bg_popup = BG_FLOAT
        c.bg_sidebar = BG_DARK
        c.bg_statusline = BG_DARK
        c.bg_highlight = CURSORLINE
        c.fg_gutter = "#3A3D46"
        c.border = "#2A2D36"
      end,

      on_highlights = function(hl, c)
        hl.CursorLine = { bg = CURSORLINE }
        hl.CursorLineNr = { fg = "#F2F2F2", bold = true }
        hl.LineNr = { fg = "#565656" }
        hl.WinSeparator = { fg = "#23262D", bg = BG }
        hl.NormalFloat = { fg = c.fg, bg = BG_FLOAT }
        hl.FloatBorder = { fg = "#3A3D46", bg = BG_FLOAT }
        hl.FloatTitle = { fg = c.fg, bg = BG_FLOAT, bold = true }
        -- The completion menu should match the float background
        hl.Pmenu = { fg = c.fg, bg = BG_FLOAT }
        hl.PmenuSel = { bg = "#2C4F7C", bold = true }
      end,
    },

    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
}
