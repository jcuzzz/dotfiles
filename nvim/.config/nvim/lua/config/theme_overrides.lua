-- Theme overrides: the one place to change colours.
--
-- lua/plugins/colorscheme.lua installs the themes and picks the active one;
-- this file says what to change on top of it. Every entry is a plain
-- highlight in nvim_set_hl() form, not any one theme's own config format,
-- and is re-applied each time a colorscheme loads:
--
--   Group = { fg = "#hex", bg = "#hex", bold = true }   replace the group
--   Group = { link = "Other" }                          look like Other
--   Group = {}                                          clear it
--
-- :Inspect with the cursor on a word shows which groups colour it.

local M = {}

-- Shared surfaces. "#000000" is pure black; these sit a hair off it so that
-- floating windows and the sidebar still read as separate surfaces. Themes
-- take them through their own palette options (see colorscheme.lua), so
-- every group the theme builds from its background picks them up.
M.surfaces = {
	bg = "#0A0A0C",
	bg_dark = "#050506", -- sidebars, tab bar, inactive surfaces
	bg_float = "#0F1013", -- popups, completion menu, hover docs
	cursorline = "#17191F",
}

local s = M.surfaces

-- Applied to every theme. Groups set only a background where the theme's
-- own text colour should show through.
M.all = {
	CursorLine = { bg = s.cursorline },
	CursorLineNr = { fg = "#F2F2F2", bold = true },
	LineNr = { fg = "#565656" },
	WinSeparator = { fg = "#23262D", bg = s.bg },
	NormalFloat = { bg = s.bg_float },
	FloatBorder = { fg = "#3A3D46", bg = s.bg_float },
	FloatTitle = { bg = s.bg_float, bold = true },
	-- The completion menu should match the float background
	Pmenu = { bg = s.bg_float },
	PmenuSel = { bg = "#2C4F7C", bold = true },
}

-- Applied after M.all, only while that colorscheme is active. Keys are the
-- names :colorscheme takes.
M.themes = {
	github_dark_default = {
		-- Python, matched to how github.com colours it:
		--   - classes (LoadError, Path) orange, but purple when called. The
		--     theme paints every LSP "class" token purple, so clear it and
		--     let treesitter decide.
		--   - builtin types in annotations (str) plain text
		--   - self and attribute access (self.name, df.col) plain text; the
		--     theme makes them blue, which drowns out the colours that mean
		--     something
		["@lsp.type.class.python"] = {},
		["@constructor.python"] = { link = "@function" },
		["@type.builtin.python"] = { link = "@variable" },
		["@variable.member.python"] = { link = "@variable" },
		["@variable.builtin.python"] = { link = "@variable" },
	},
}

return M
