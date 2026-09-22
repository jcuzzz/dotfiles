# Neovim config

Modular Neovim IDE setup. Entry point is `init.lua`, which loads four files
from `lua/config/` and then hands off to lazy.nvim, which imports every file
in `lua/plugins/`.

## Adding, removing and editing plugins

**Add a plugin:** create a new file in `lua/plugins/`. Any name works.

```lua
-- lua/plugins/example.lua
return {
  {
    "owner/repo",
    event = "VeryLazy",        -- when to load it; see below
    opts = { some = "option" }, -- passed to the plugin's setup()
    keys = {
      { "<leader>zz", "<cmd>DoThing<CR>", desc = "Do the thing" },
    },
  },
}
```

Restart Neovim, or run `:Lazy sync`. That is the whole process.

**Remove a plugin:** delete its file, then `:Lazy clean`.

**Edit a plugin:** open its file and change `opts`. `<leader>fn` finds files
in this config from anywhere.

**Lazy-loading triggers** (leave one out and the plugin loads at startup):

| Trigger | Loads when |
|---|---|
| `event = "VeryLazy"` | shortly after startup, once the UI is drawn |
| `event = "BufReadPre"` | a real file is opened |
| `event = "InsertEnter"` | you enter insert mode |
| `ft = "python"` | you open a file of that type |
| `cmd = "Foo"` | you run `:Foo` |
| `keys = { ... }` | you press one of those keys |

## Layout

```
init.lua                  loads the four config modules
lua/config/
  options.lua             vim.opt settings; has vim.g.have_nerd_font
  keymaps.lua             keybinds that belong to no plugin
  autocmds.lua            yank highlight, per-language indent, etc.
  lazy.lua                plugin manager bootstrap, leader key
lua/plugins/
  colorscheme.lua         tokyonight, forced to a black bg and no italics
  lsp.lua                 mason + language servers  <- add languages here
  completion.lua          blink.cmp, snippets
  formatting.lua          conform.nvim, format-on-save
  linting.lua             nvim-lint (thin; most linting comes from LSP)
  treesitter.lua          syntax trees, text objects
  telescope.lua           fuzzy finder
  explorer.lua            neo-tree file sidebar
  git.lua                 gitsigns, diffview
  ui.lua                  lualine, bufferline, which-key, indent guides
  editor.lua              surround, autopairs, todo-comments, sessions
  navigation.lua          trouble, aerial outline
  terminal.lua            toggleterm, lazygit
  dap.lua                 debugger
  testing.lua             neotest
```

`lazy-lock.json` pins every plugin to an exact commit. Keep it in version
control and this config reproduces exactly on another machine
(`:Lazy restore`).

## Useful commands

| Command | What it does |
|---|---|
| `:Lazy` | plugin dashboard: install, update, profile startup |
| `:Mason` | install/remove language servers, formatters, linters |
| `:checkhealth` | diagnose anything that is not working |
| `:LspInfo` | which servers are attached to this buffer |
| `:ConformInfo` | which formatters apply here, and whether they are installed |
| `:FormatDisable` | turn off format-on-save (`:FormatEnable` to restore) |
| `:Telescope keymaps` | search every keybind (also `<leader>fk`) |

## Adding a language

Open `lua/plugins/lsp.lua` and add an entry to the `servers` table:

```lua
rust_analyzer = {},
```

mason installs it on the next start. Add a formatter for it in
`lua/plugins/formatting.lua` under `formatters_by_ft`, and its mason package
name to `mason-tool-installer`'s `ensure_installed` in `lsp.lua`.

Add the treesitter parser in `lua/plugins/treesitter.lua` under
`ensure_installed` (or let `auto_install` handle it).

## Notes for this machine

- **C#** needs the .NET SDK, which is not installed. `sudo apt-get install
  -y dotnet-sdk-8.0`, then add `omnisharp` to the `servers` table.
- **lazygit** (`<leader>gg`) is not installed. `sudo apt-get install -y lazygit`.
- **SQL**: `sqls` works for keyword completion. For schema-aware completion it
  needs a database connection - see the comment in `lsp.lua`.
- **Icons** assume a Nerd Font in your terminal. If you see boxes, set
  `vim.g.have_nerd_font = false` at the top of `lua/config/options.lua`.
- **nvim-treesitter** is pinned to the `master` branch, which upstream has
  frozen in favour of a rewritten `main` branch. master works on this Neovim
  version; migrating is a separate job that also needs the tree-sitter CLI.
