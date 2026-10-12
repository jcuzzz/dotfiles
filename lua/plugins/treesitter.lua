-- Treesitter: parses each file into a real syntax tree.
--
-- That tree drives accurate highlighting, indentation, folding, and the
-- structural text objects below - `vaf` selects a whole function, `vic` the
-- inside of a class, no matter how they are formatted.
--
--   :TSUpdate            update the installed parsers
--   :TSInstall <lang>    add a parser by hand
--   :InspectTree         see the syntax tree for the current buffer
--
-- Note: this pins the `master` branch. Upstream has frozen master in favour
-- of a rewritten `main` branch, which additionally requires the tree-sitter
-- CLI to be installed. master still works on this Neovim version; migrating
-- is a separate job whenever you want to do it.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "python", "lua", "luadoc", "go", "gomod", "gosum", "gowork",
          "javascript", "typescript", "tsx", "html", "css", "scss",
          "c_sharp", "sql",
          "json", "jsonc", "yaml", "toml", "xml",
          "bash", "dockerfile", "gitignore", "gitcommit", "diff",
          "markdown", "markdown_inline", "regex", "vim", "vimdoc", "query",
        },

        -- Off: this checks for a missing parser on every buffer you open,
        -- which means a filesystem probe per file. The languages above are
        -- already covered; for anything else run :TSInstall <lang> once.
        auto_install = false,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },

        indent = { enable = true },

        -- Press Enter to select the node under the cursor, then Enter again
        -- to widen the selection to its parent. Backspace shrinks it.
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "<CR>",
            scope_incremental = "<S-CR>",
            node_decremental = "<BS>",
          },
        },

        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- jump forward to the next one if not inside it
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["ai"] = "@conditional.outer",
              ["ii"] = "@conditional.inner",
              ["a/"] = "@comment.outer",
            },
          },

          move = {
            enable = true,
            set_jumps = true, -- so Ctrl-o jumps back
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
          },

          -- Swap an argument with the one beside it
          swap = {
            enable = true,
            swap_next = { ["<leader>a"] = "@parameter.inner" },
            swap_previous = { ["<leader>A"] = "@parameter.inner" },
          },
        },
      })
    end,
  },
}
