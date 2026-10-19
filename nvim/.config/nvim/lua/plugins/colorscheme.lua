-- Colour schemes.
--
-- Every theme below is installed; ACTIVE is the one Neovim starts with. Only
-- the active theme loads at startup. The others load on demand, so any of
-- them can be tried for the session with :colorscheme <name> or
-- :Telescope colorscheme.
--
--   vague                 muted, low-contrast
--   github_dark_default   github.com's dark palette
--   tokyonight-night      ships explicit styles for every plugin here
--
-- Colour changes go in lua/config/theme_overrides.lua, not here. This file
-- only holds what has to go through a theme's own options: its background
-- palette, so every group it builds picks up the shared surfaces.
--
-- Italics are removed everywhere by strip_italics(). Themes and plugins both
-- like to sneak them in, so it runs after every colorscheme change rather
-- than trusting each one's settings.

local ACTIVE = "vague"

local overrides = require("config.theme_overrides")
local s = overrides.surfaces

local function apply_overrides(colors_name)
	for _, groups in ipairs({ overrides.all, overrides.themes[colors_name] or {} }) do
		for name, spec in pairs(groups) do
			vim.api.nvim_set_hl(0, name, spec)
		end
	end
end

local function strip_italics()
	for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
		if def.italic and not def.link then
			def.italic = false
			pcall(vim.api.nvim_set_hl, 0, name, def)
		end
	end
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("user_theme", { clear = true }),
	callback = function(args)
		apply_overrides(args.match)
		-- Deferred so it also catches italics that plugins add in their own
		-- ColorScheme handlers
		vim.schedule(strip_italics)
	end,
})

-- The active theme loads before anything draws and before every other
-- plugin; the rest stay lazy until :colorscheme asks for them.
local function theme(colorscheme, spec)
	spec.lazy = ACTIVE ~= colorscheme
	spec.priority = 1000
	spec.config = function(_, opts)
		require(spec.main).setup(opts)
		if ACTIVE == colorscheme then
			vim.cmd.colorscheme(colorscheme)
		end
	end
	return spec
end

return {
	theme("vague", {
		"vague-theme/vague.nvim",
		main = "vague",
		opts = {
			italic = false,
			colors = {
				bg = s.bg,
				inactiveBg = s.bg_dark,
				line = s.cursorline,
			},
		},
	}),

	theme("github_dark_default", {
		"projekt0n/github-nvim-theme",
		main = "github-theme",
		opts = {
			options = {
				terminal_colors = true,
				styles = {
					comments = "NONE",
					keywords = "bold",
					functions = "NONE",
					variables = "NONE",
				},
			},
			-- bg0-bg3 are "spec" keys; under `palettes` they are ignored
			specs = {
				github_dark_default = {
					bg0 = s.bg_dark,
					bg1 = s.bg,
					bg2 = s.bg_float,
					bg3 = s.cursorline,
				},
			},
		},
	}),

	theme("tokyonight-night", {
		"folke/tokyonight.nvim",
		main = "tokyonight",
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
			on_colors = function(c)
				c.bg = s.bg
				c.bg_dark = s.bg_dark
				c.bg_dark1 = s.bg_dark
				c.bg_float = s.bg_float
				c.bg_popup = s.bg_float
				c.bg_sidebar = s.bg_dark
				c.bg_statusline = s.bg_dark
				c.bg_highlight = s.cursorline
				c.fg_gutter = "#3A3D46"
				c.border = "#2A2D36"
			end,
		},
	}),
}
