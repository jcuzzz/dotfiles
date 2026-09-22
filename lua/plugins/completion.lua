-- Autocompletion.
--
-- blink.cmp is the current standard completion engine: it draws the popup
-- and merges candidates from the language server, snippets, open buffers
-- and file paths.
--
-- Keys (the "super-tab" preset):
--   <Tab> / <S-Tab>   accept the selected item, or jump through a snippet's
--                     placeholders. Falls through to a real tab when the
--                     menu is closed, so indenting still works.
--   <C-n> / <C-p>     next / previous item
--   <C-e>             dismiss the menu
--   <C-space>         open the menu on demand, then cycle documentation
--
-- Prefer Enter to accept instead? Change `preset` to "enter". Other presets:
-- "default" (Ctrl-y accepts), "super-tab", "enter". See :help blink-cmp-config

return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    version = "1.*", -- release tags ship a prebuilt fuzzy-matcher binary

    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = {
          -- A large library of ready-made snippets, in VS Code's format
          "rafamadriz/friendly-snippets",
        },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
          -- Your own snippets, if you ever write any:
          --   ~/.config/nvim/snippets/<filetype>.json
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })
        end,
      },
    },

    opts = {
      keymap = { preset = "super-tab" },

      snippets = { preset = "luasnip" },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        -- Show the docs panel beside the menu after a short pause
        documentation = { auto_show = true, auto_show_delay_ms = 250 },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" }, -- syntax-highlight the candidates
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
            },
          },
        },
        -- Inline preview of the top candidate. Off by default because it
        -- competes visually with real text; set to true to try it.
        ghost_text = { enabled = false },
      },

      signature = { enabled = true, window = { border = "rounded" } },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          -- lazydev supplies the Neovim API types when editing this config
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },

    opts_extend = { "sources.default" },
  },

  -- Completion and docs for the Neovim Lua API, but only inside plugin
  -- configs. This is what makes editing THIS config comfortable.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
    specs = {
      {
        "saghen/blink.cmp",
        opts = { sources = { default = { "lazydev" } } },
      },
    },
  },
}
