-- Linting for tools that are not language servers.
--
-- Most linting here already comes from the LSP layer (ruff for Python,
-- eslint for JS/TS, staticcheck via gopls), so this file is deliberately
-- thin - it covers the gaps. Add a linter by putting it in
-- linters_by_ft and adding its mason package to lsp.lua.

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },

    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- Populated as you need it, e.g.
        --   markdown = { "markdownlint" },
        --   dockerfile = { "hadolint" },
        --   sh = { "shellcheck" },
      }

      local group = vim.api.nvim_create_augroup("user_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = group,
        callback = function()
          -- Only lint real, modifiable files
          if vim.bo.modifiable and vim.bo.buftype == "" then
            lint.try_lint()
          end
        end,
      })

      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Lint buffer" })
    end,
  },
}
