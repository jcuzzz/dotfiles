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
-- This is the rewritten `main` branch (the old `master` is frozen and does
-- not support Neovim 0.12). It only installs parsers and queries; Neovim
-- itself does the highlighting and folding, switched on per buffer below.
-- Installing parsers needs the tree-sitter CLI (0.26.1+) and a C compiler.

local parsers = {
  "python", "lua", "luadoc", "go", "gomod", "gosum", "gowork",
  "javascript", "typescript", "tsx", "html", "css", "scss",
  "c_sharp", "sql",
  "json", "yaml", "toml", "xml", -- json covers jsonc too
  "bash", "dockerfile", "gitignore", "gitcommit", "diff",
  "markdown", "markdown_inline", "regex", "vim", "vimdoc", "query",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- No-op for parsers already installed; missing ones build in the
      -- background. For anything else run :TSInstall <lang> once.
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(args)
          -- Fails quietly when there is no parser for this filetype
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- Press Enter to select the node under the cursor, then Enter
          -- again to widen the selection to its parent. Backspace shrinks
          -- it. Built on Neovim's own `an` / `in`.
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, remap = true, desc = desc })
          end
          map("n", "<CR>", "van", "Select node")
          map("x", "<CR>", "an", "Widen selection")
          map("x", "<BS>", "in", "Shrink selection")
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true }, -- jump forward to the next one if not inside it
        move = { set_jumps = true },   -- so Ctrl-o jumps back
      })

      local select = require("nvim-treesitter-textobjects.select")
      for lhs, query in pairs({
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
      }) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(query, "textobjects")
        end, { desc = query })
      end

      local move = require("nvim-treesitter-textobjects.move")
      for lhs, spec in pairs({
        ["]f"] = { move.goto_next_start, "@function.outer" },
        ["]c"] = { move.goto_next_start, "@class.outer" },
        ["[f"] = { move.goto_previous_start, "@function.outer" },
        ["[c"] = { move.goto_previous_start, "@class.outer" },
      }) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          spec[1](spec[2], "textobjects")
        end, { desc = spec[2] })
      end

      -- Swap an argument with the one beside it
      local swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap with next parameter" })
      vim.keymap.set("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap with previous parameter" })
    end,
  },
}
